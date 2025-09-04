const socketIo = require('socket.io');
const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Room = require('../models/Room');
const { RoomActivity, RoomUserStatus } = require('../models/RoomActivity');

class SocketService {
  constructor() {
    this.io = null;
    this.connectedUsers = new Map(); // userId -> { socketId, roomId, userInfo }
    this.roomUsers = new Map(); // roomId -> Set of userIds
  }

  // تهيئة Socket.IO
  initialize(server) {
    this.io = socketIo(server, {
      cors: {
        origin: "*",
        methods: ["GET", "POST"]
      },
      transports: ['websocket', 'polling']
    });

    // Middleware للمصادقة
    this.io.use(async (socket, next) => {
      try {
        const token = socket.handshake.auth.token || socket.handshake.headers.authorization?.replace('Bearer ', '');
        
        if (!token) {
          return next(new Error('Authentication error: No token provided'));
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        const user = await User.findById(decoded.userId);
        
        if (!user) {
          return next(new Error('Authentication error: User not found'));
        }

        socket.userId = user._id.toString();
        socket.userInfo = {
          displayName: user.displayName,
          profilePicture: user.profilePicture,
          role: 'listener'
        };
        
        next();
      } catch (error) {
        next(new Error('Authentication error: Invalid token'));
      }
    });

    // معالجة الاتصالات
    this.io.on('connection', (socket) => {
      console.log(`User ${socket.userId} connected with socket ${socket.id}`);
      
      // حفظ معلومات الاتصال
      this.connectedUsers.set(socket.userId, {
        socketId: socket.id,
        roomId: null,
        userInfo: socket.userInfo,
        connectedAt: new Date()
      });

      // الانضمام لغرفة
      socket.on('join_room', async (data) => {
        await this.handleJoinRoom(socket, data);
      });

      // مغادرة الغرفة
      socket.on('leave_room', async (data) => {
        await this.handleLeaveRoom(socket, data);
      });

      // إرسال رسالة
      socket.on('send_message', async (data) => {
        await this.handleSendMessage(socket, data);
      });

      // طلب الانتقال للمايك
      socket.on('request_mic', async (data) => {
        await this.handleMicRequest(socket, data);
      });

      // مغادرة المايك
      socket.on('leave_mic', async (data) => {
        await this.handleLeaveMic(socket, data);
      });

      // تحديث حالة المستخدم
      socket.on('update_status', async (data) => {
        await this.handleUpdateStatus(socket, data);
      });

      // قطع الاتصال
      socket.on('disconnect', () => {
        this.handleDisconnect(socket);
      });
    });

    return this.io;
  }

  // الانضمام لغرفة
  async handleJoinRoom(socket, { roomId }) {
    try {
      const room = await Room.findOne({ roomId })
        .populate('ownerId', 'displayName profilePicture')
        .populate('seats.userId', 'displayName profilePicture');

      if (!room) {
        socket.emit('error', { message: 'الغرفة غير موجودة' });
        return;
      }

      // التحقق من الحظر
      if (room.isUserBanned(socket.userId)) {
        socket.emit('error', { message: 'أنت محظور من هذه الغرفة' });
        return;
      }

      // الانضمام لغرفة Socket.IO
      socket.join(roomId);
      
      // تحديث معلومات الاتصال
      const userConnection = this.connectedUsers.get(socket.userId);
      if (userConnection) {
        userConnection.roomId = roomId;
        userConnection.userInfo.role = room.getUserRole(socket.userId);
      }

      // إضافة للمجموعة
      if (!this.roomUsers.has(roomId)) {
        this.roomUsers.set(roomId, new Set());
      }
      this.roomUsers.get(roomId).add(socket.userId);

      // تحديث حالة المستخدم في قاعدة البيانات
      await RoomUserStatus.findOneAndUpdate(
        { roomId: room._id, userId: socket.userId },
        {
          status: 'online',
          role: room.getUserRole(socket.userId),
          'connectionInfo.lastSeen': new Date()
        },
        { upsert: true }
      );

      // إرسال معلومات الغرفة للمستخدم
      socket.emit('room_joined', {
        room: {
          _id: room._id,
          roomId: room.roomId,
          title: room.title,
          description: room.description,
          owner: room.ownerId,
          seats: room.seats,
          settings: room.settings,
          stats: room.stats
        },
        userRole: room.getUserRole(socket.userId),
        micStats: room.getMicStats(),
        layout: room.getMicLayout()
      });

      // إشعار باقي المستخدمين
      socket.to(roomId).emit('user_joined', {
        userId: socket.userId,
        userInfo: socket.userInfo,
        participantCount: room.getCurrentParticipantCount() + 1
      });

      // إرسال قائمة المستخدمين المتصلين
      const connectedInRoom = await this.getConnectedUsersInRoom(roomId);
      this.io.to(roomId).emit('users_update', { connectedUsers: connectedInRoom });

    } catch (error) {
      console.error('Error in join_room:', error);
      socket.emit('error', { message: 'حدث خطأ أثناء الانضمام للغرفة' });
    }
  }

  // مغادرة الغرفة
  async handleLeaveRoom(socket, { roomId }) {
    try {
      socket.leave(roomId);
      
      // إزالة من المجموعة
      if (this.roomUsers.has(roomId)) {
        this.roomUsers.get(roomId).delete(socket.userId);
      }

      // تحديث معلومات الاتصال
      const userConnection = this.connectedUsers.get(socket.userId);
      if (userConnection) {
        userConnection.roomId = null;
      }

      // تحديث حالة المستخدم
      await RoomUserStatus.findOneAndUpdate(
        { roomId: roomId, userId: socket.userId },
        { 
          status: 'offline',
          'connectionInfo.lastSeen': new Date()
        }
      );

      // إشعار باقي المستخدمين
      socket.to(roomId).emit('user_left', {
        userId: socket.userId,
        userInfo: socket.userInfo
      });

      // تحديث قائمة المستخدمين
      const connectedInRoom = await this.getConnectedUsersInRoom(roomId);
      this.io.to(roomId).emit('users_update', { connectedUsers: connectedInRoom });

    } catch (error) {
      console.error('Error in leave_room:', error);
    }
  }

  // إرسال رسالة
  async handleSendMessage(socket, { roomId, message, replyTo }) {
    try {
      const room = await Room.findOne({ roomId });
      if (!room) {
        socket.emit('error', { message: 'الغرفة غير موجودة' });
        return;
      }

      // التحقق من إعدادات الدردشة
      if (!room.settings.chatSettings.isEnabled) {
        socket.emit('error', { message: 'الدردشة معطلة في هذه الغرفة' });
        return;
      }

      const user = await User.findById(socket.userId);
      const userRole = room.getUserRole(socket.userId);

      // إنشاء الرسالة
      const newMessage = await RoomMessage.createTextMessage(
        room._id,
        { ...user.toObject(), role: userRole },
        message,
        replyTo
      );

      // إرسال الرسالة لجميع المستخدمين في الغرفة
      this.io.to(roomId).emit('new_message', {
        message: {
          _id: newMessage._id,
          messageId: newMessage.messageId,
          messageType: newMessage.messageType,
          senderInfo: newMessage.senderInfo,
          content: newMessage.content,
          replyTo: newMessage.replyTo,
          createdAt: newMessage.createdAt
        }
      });

      // تحديث إحصائيات الغرفة
      room.stats.totalMessages += 1;
      room.updateLastActivity();
      await room.save();

    } catch (error) {
      console.error('Error in send_message:', error);
      socket.emit('error', { message: 'حدث خطأ أثناء إرسال الرسالة' });
    }
  }

  // طلب الانتقال للمايك
  async handleMicRequest(socket, { roomId, seatNumber }) {
    try {
      const room = await Room.findOne({ roomId });
      if (!room) {
        socket.emit('error', { message: 'الغرفة غير موجودة' });
        return;
      }

      const user = await User.findById(socket.userId);
      const userRole = room.getUserRole(socket.userId);

      // التحقق من توفر المقعد
      const seat = room.seats.find(s => s.seatNumber === seatNumber);
      if (!seat || seat.userId) {
        socket.emit('error', { message: 'المقعد غير متاح' });
        return;
      }

      // التحقق من الصلاحيات للمقاعد VIP
      if (seat.isVIP && !['owner', 'admin'].includes(userRole)) {
        socket.emit('error', { message: 'هذا مقعد VIP للمدراء فقط' });
        return;
      }

      // إضافة المستخدم للمقعد
      const success = room.addUserToSeat(socket.userId, seatNumber);
      if (!success) {
        socket.emit('error', { message: 'فشل في الانتقال للمايك' });
        return;
      }

      await room.save();

      // تحديث دور المستخدم
      await RoomUserStatus.findOneAndUpdate(
        { roomId: room._id, userId: socket.userId },
        {
          role: 'speaker',
          seatInfo: {
            seatNumber,
            isVIP: seat.isVIP,
            isMuted: false,
            joinedSeatAt: new Date()
          }
        }
      );

      // إنشاء رسالة انتقال للمايك
      await RoomMessage.createMicJoinMessage(room._id, user, seatNumber);

      // إشعار جميع المستخدمين
      this.io.to(roomId).emit('mic_update', {
        action: 'user_joined_mic',
        seatNumber,
        userId: socket.userId,
        userInfo: {
          ...socket.userInfo,
          role: 'speaker'
        },
        seats: room.seats,
        micStats: room.getMicStats()
      });

      // إنشاء نشاط
      await RoomActivity.createActivity(
        room._id,
        'user_moved_to_mic',
        socket.userId,
        { seatInfo: { toSeat: seatNumber } }
      );

    } catch (error) {
      console.error('Error in request_mic:', error);
      socket.emit('error', { message: 'حدث خطأ أثناء الانتقال للمايك' });
    }
  }

  // مغادرة المايك
  async handleLeaveMic(socket, { roomId }) {
    try {
      const room = await Room.findOne({ roomId });
      if (!room) {
        socket.emit('error', { message: 'الغرفة غير موجودة' });
        return;
      }

      const seat = room.seats.find(s => s.userId && s.userId.toString() === socket.userId);
      if (!seat) {
        socket.emit('error', { message: 'أنت لست على أي مايك' });
        return;
      }

      const seatNumber = seat.seatNumber;
      const user = await User.findById(socket.userId);

      // إزالة المستخدم من المقعد
      room.removeUserFromSeat(socket.userId);
      await room.save();

      // تحديث دور المستخدم
      await RoomUserStatus.findOneAndUpdate(
        { roomId: room._id, userId: socket.userId },
        {
          role: 'listener',
          $unset: { seatInfo: 1 }
        }
      );

      // إنشاء رسالة مغادرة المايك
      await RoomMessage.createMicLeaveMessage(room._id, user, seatNumber);

      // إشعار جميع المستخدمين
      this.io.to(roomId).emit('mic_update', {
        action: 'user_left_mic',
        seatNumber,
        userId: socket.userId,
        seats: room.seats,
        micStats: room.getMicStats()
      });

      // إنشاء نشاط
      await RoomActivity.createActivity(
        room._id,
        'user_left_mic',
        socket.userId,
        { seatInfo: { fromSeat: seatNumber } }
      );

    } catch (error) {
      console.error('Error in leave_mic:', error);
      socket.emit('error', { message: 'حدث خطأ أثناء مغادرة المايك' });
    }
  }

  // تحديث حالة المستخدم
  async handleUpdateStatus(socket, { status }) {
    try {
      const userConnection = this.connectedUsers.get(socket.userId);
      if (!userConnection || !userConnection.roomId) return;

      await RoomUserStatus.findOneAndUpdate(
        { roomId: userConnection.roomId, userId: socket.userId },
        { 
          status,
          'connectionInfo.lastSeen': new Date()
        }
      );

      // إشعار المستخدمين الآخرين
      socket.to(userConnection.roomId).emit('user_status_update', {
        userId: socket.userId,
        status
      });

    } catch (error) {
      console.error('Error in update_status:', error);
    }
  }

  // قطع الاتصال
  handleDisconnect(socket) {
    console.log(`User ${socket.userId} disconnected`);
    
    const userConnection = this.connectedUsers.get(socket.userId);
    if (userConnection && userConnection.roomId) {
      // إشعار المستخدمين في الغرفة
      socket.to(userConnection.roomId).emit('user_disconnected', {
        userId: socket.userId
      });

      // إزالة من مجموعة الغرفة
      if (this.roomUsers.has(userConnection.roomId)) {
        this.roomUsers.get(userConnection.roomId).delete(socket.userId);
      }
    }

    // إزالة من قائمة المتصلين
    this.connectedUsers.delete(socket.userId);
  }

  // إرسال تحديث فوري لجميع المستخدمين في الغرفة
  async broadcastToRoom(roomId, event, data) {
    if (this.io) {
      this.io.to(roomId).emit(event, data);
    }
  }

  // إرسال تحديث تغيير عدد المايكات
  async broadcastMicCountChange(roomId, oldCount, newCount, newSeats, affectedUsers) {
    await this.broadcastToRoom(roomId, 'mic_count_changed', {
      oldCount,
      newCount,
      newSeats,
      affectedUsers,
      timestamp: new Date().toISOString()
    });
  }

  // إرسال تحديث إعدادات الغرفة
  async broadcastRoomSettingsUpdate(roomId, settingType, oldValue, newValue) {
    await this.broadcastToRoom(roomId, 'room_settings_updated', {
      settingType,
      oldValue,
      newValue,
      timestamp: new Date().toISOString()
    });
  }

  // الحصول على المستخدمين المتصلين في غرفة
  async getConnectedUsersInRoom(roomId) {
    const roomUserIds = this.roomUsers.get(roomId) || new Set();
    const connectedUsers = [];

    for (const userId of roomUserIds) {
      const userConnection = this.connectedUsers.get(userId);
      if (userConnection) {
        connectedUsers.push({
          userId,
          userInfo: userConnection.userInfo,
          connectedAt: userConnection.connectedAt
        });
      }
    }

    return connectedUsers;
  }

  // الحصول على عدد المستخدمين المتصلين
  getConnectedUsersCount() {
    return this.connectedUsers.size;
  }

  // الحصول على عدد المستخدمين في غرفة معينة
  getRoomUsersCount(roomId) {
    return this.roomUsers.get(roomId)?.size || 0;
  }
}

module.exports = new SocketService();

