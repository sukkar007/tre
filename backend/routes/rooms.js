const fastify = require('fastify');
const Room = require('../models/Room');
const { RoomActivity, RoomUserStatus } = require('../models/RoomActivity');
const RoomMessage = require('../models/RoomMessage');
const User = require('../models/User');

async function roomRoutes(fastify, options) {
  
  // إنشاء غرفة جديدة
  fastify.post('/create', async (request, reply) => {
    try {
      const { title, description, category, tags, micCount = 6, isPrivate = false } = request.body;
      const userId = request.user.id;
      
      // التحقق من صحة عدد المايكات
      if (![2, 6, 12, 16, 20].includes(micCount)) {
        return reply.status(400).send({
          success: false,
          message: 'عدد المايكات يجب أن يكون 2، 6، 12، 16، أو 20'
        });
      }
      
      // إنشاء معرف فريد للغرفة
      const roomId = `room_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
      
      // إنشاء المقاعد حسب عدد المايكات
      const seats = [];
      const vipMicsCount = micCount === 2 ? 0 : micCount === 6 ? 1 : micCount === 12 ? 2 : micCount === 16 ? 3 : 4;
      
      for (let i = 1; i <= micCount; i++) {
        seats.push({
          seatNumber: i,
          userId: null,
          isVIP: i <= vipMicsCount,
          isMuted: false,
          isLocked: false,
          joinedAt: null
        });
      }
      
      // إنشاء الغرفة
      const room = new Room({
        roomId,
        title: title.trim(),
        description: description?.trim(),
        category,
        tags: tags || [],
        ownerId: userId,
        seats,
        settings: {
          micSettings: {
            totalMics: micCount,
            vipMics: vipMicsCount,
            guestMics: micCount - vipMicsCount
          },
          accessSettings: {
            isPrivate
          }
        }
      });
      
      await room.save();
      
      // إنشاء نشاط إنشاء الغرفة
      await RoomActivity.createActivity(
        room._id,
        'room_created',
        userId,
        { micCount, isPrivate }
      );
      
      // إضافة المالك كمستمع
      await RoomUserStatus.create({
        roomId: room._id,
        userId,
        status: 'online',
        role: 'owner',
        connectionInfo: {
          joinedAt: new Date(),
          lastSeen: new Date(),
          deviceType: request.headers['user-agent']?.includes('Mobile') ? 'mobile' : 'desktop',
          platform: 'web'
        }
      });
      
      reply.send({
        success: true,
        message: 'تم إنشاء الغرفة بنجاح',
        data: {
          roomId: room.roomId,
          _id: room._id,
          title: room.title,
          micCount: room.settings.micSettings.totalMics,
          layout: room.getMicLayout()
        }
      });
      
    } catch (error) {
      fastify.log.error(error);
      reply.status(500).send({
        success: false,
        message: 'حدث خطأ أثناء إنشاء الغرفة'
      });
    }
  });
  
  // الحصول على تفاصيل الغرفة
  fastify.get('/:roomId', async (request, reply) => {
    try {
      const { roomId } = request.params;
      const userId = request.user.id;
      
      const room = await Room.findOne({ roomId })
        .populate('ownerId', 'displayName profilePicture')
        .populate('seats.userId', 'displayName profilePicture')
        .populate('admins.userId', 'displayName profilePicture');
      
      if (!room) {
        return reply.status(404).send({
          success: false,
          message: 'الغرفة غير موجودة'
        });
      }
      
      // التحقق من الحظر
      if (room.isUserBanned(userId)) {
        return reply.status(403).send({
          success: false,
          message: 'أنت محظور من هذه الغرفة'
        });
      }
      
      // الحصول على دور المستخدم
      const userRole = room.getUserRole(userId);
      
      // الحصول على إحصائيات المايكات
      const micStats = room.getMicStats();
      
      // الحصول على المستخدمين المتصلين
      const connectedUsers = await RoomActivity.getCurrentUsers(room._id);
      
      reply.send({
        success: true,
        data: {
          room: {
            _id: room._id,
            roomId: room.roomId,
            title: room.title,
            description: room.description,
            category: room.category,
            tags: room.tags,
            owner: room.ownerId,
            admins: room.admins,
            seats: room.seats,
            settings: room.settings,
            status: room.status,
            stats: room.stats,
            createdAt: room.createdAt,
            lastActiveAt: room.lastActiveAt
          },
          userRole,
          micStats,
          connectedUsers,
          layout: room.getMicLayout(),
          waitingQueue: room.waitingQueue
        }
      });
      
    } catch (error) {
      fastify.log.error(error);
      reply.status(500).send({
        success: false,
        message: 'حدث خطأ أثناء جلب تفاصيل الغرفة'
      });
    }
  });
  
  // تغيير عدد المايكات
  fastify.put('/:roomId/mic-count', async (request, reply) => {
    try {
      const { roomId } = request.params;
      const { newCount } = request.body;
      const userId = request.user.id;
      
      const room = await Room.findOne({ roomId });
      if (!room) {
        return reply.status(404).send({
          success: false,
          message: 'الغرفة غير موجودة'
        });
      }
      
      // التحقق من الصلاحية
      const canChange = room.canChangeMicCount(userId, newCount);
      if (!canChange.allowed) {
        return reply.status(403).send({
          success: false,
          message: canChange.reason
        });
      }
      
      const oldCount = room.settings.micSettings.totalMics;
      const affectedUsers = [];
      
      // حفظ المستخدمين المتأثرين قبل التغيير
      if (newCount < oldCount) {
        const usersToMove = room.seats.slice(newCount).filter(seat => seat.userId);
        for (const seat of usersToMove) {
          const user = await User.findById(seat.userId);
          affectedUsers.push({
            userId: seat.userId,
            userInfo: {
              displayName: user.displayName,
              profilePicture: user.profilePicture
            },
            action: 'moved_to_queue',
            fromSeat: seat.seatNumber
          });
        }
      }
      
      // تغيير عدد المايكات
      room.changeMicCount(newCount, true);
      await room.save();
      
      // تحديث حالة المستخدمين المتأثرين
      for (const affected of affectedUsers) {
        await RoomUserStatus.findOneAndUpdate(
          { roomId: room._id, userId: affected.userId },
          {
            role: 'listener',
            $unset: { seatInfo: 1 }
          }
        );
        
        // إضافة للطابور
        room.addToWaitingQueue(affected.userId, 1); // أولوية عالية
      }
      
      await room.save();
      
      // إنشاء نشاط التغيير
      await RoomActivity.createActivity(
        room._id,
        'mic_count_changed',
        userId,
        {
          micChange: {
            fromCount: oldCount,
            toCount: newCount,
            affectedUsers
          }
        }
      );
      
      // إنشاء رسالة في الدردشة
      const user = await User.findById(userId);
      await RoomMessage.create({
        messageId: `${room._id}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
        roomId: room._id,
        senderId: userId,
        messageType: 'system_settings',
        senderInfo: {
          displayName: user.displayName,
          profilePicture: user.profilePicture,
          role: 'owner',
          nameColor: '#7C3AED'
        },
        content: {
          text: `تم تغيير عدد المايكات من ${oldCount} إلى ${newCount}`,
          metadata: new Map([
            ['action', 'mic_count_change'],
            ['oldCount', oldCount],
            ['newCount', newCount],
            ['affectedUsersCount', affectedUsers.length]
          ])
        },
        priority: 'high'
      });
      
      // إرسال تحديث فوري لجميع المستخدمين في الغرفة
      const socketService = require('../services/socketService');
      await socketService.broadcastMicCountChange(
        roomId,
        oldCount,
        newCount,
        room.seats,
        affectedUsers
      );
      
      // إرسال رسائل مغادرة المايك للمستخدمين المتأثرين
      for (const affected of affectedUsers) {
        const affectedUser = await User.findById(affected.userId);
        await RoomMessage.createMicLeaveMessage(room._id, affectedUser, affected.fromSeat);
        
        // إنشاء نشاط مغادرة المايك
        await RoomActivity.createActivity(
          room._id,
          'user_left_mic',
          affected.userId,
          { seatInfo: { fromSeat: affected.fromSeat } }
        );
      }
      
      // إرسال تحديث المايكات عبر WebSocket
      await socketService.broadcastToRoom(roomId, 'mic_layout_updated', {
        newCount,
        newLayout: room.getMicLayout(),
        newSeats: room.seats,
        micStats: room.getMicStats(),
        waitingQueue: room.waitingQueue,
        affectedUsers,
        timestamp: new Date().toISOString()
      });
      
      reply.send({
        success: true,
        message: canChange.warning || 'تم تغيير عدد المايكات بنجاح',
        data: {
          oldCount,
          newCount,
          affectedUsers,
          newLayout: room.getMicLayout(),
          micStats: room.getMicStats(),
          newSeats: room.seats,
          waitingQueue: room.waitingQueue
        }
      });
      
    } catch (error) {
      fastify.log.error(error);
      reply.status(500).send({
        success: false,
        message: 'حدث خطأ أثناء تغيير عدد المايكات'
      });
    }
  });
  
  // الانضمام للغرفة
  fastify.post('/:roomId/join', async (request, reply) => {
    try {
      const { roomId } = request.params;
      const userId = request.user.id;
      
      const room = await Room.findOne({ roomId });
      if (!room) {
        return reply.status(404).send({
          success: false,
          message: 'الغرفة غير موجودة'
        });
      }
      
      // التحقق من الحظر
      if (room.isUserBanned(userId)) {
        return reply.status(403).send({
          success: false,
          message: 'أنت محظور من هذه الغرفة'
        });
      }
      
      // التحقق من الوصول للغرف الخاصة
      if (room.settings.accessSettings.isPrivate) {
        const hasInvitation = room.invitations.find(inv => 
          inv.userId.toString() === userId && 
          inv.status === 'pending' && 
          inv.expiresAt > new Date()
        );
        
        if (!hasInvitation && room.ownerId.toString() !== userId) {
          return reply.status(403).send({
            success: false,
            message: 'هذه غرفة خاصة وتحتاج دعوة للدخول'
          });
        }
      }
      
      // إضافة المستخدم للمستمعين
      const existingListener = room.listeners.find(l => l.userId.toString() === userId);
      if (!existingListener) {
        room.listeners.push({
          userId,
          joinedAt: new Date(),
          lastSeen: new Date()
        });
        
        room.stats.totalJoins += 1;
        room.updateLastActivity();
        room.updatePeakParticipants();
        
        await room.save();
      }
      
      // إنشاء/تحديث حالة المستخدم
      await RoomUserStatus.findOneAndUpdate(
        { roomId: room._id, userId },
        {
          status: 'online',
          role: room.getUserRole(userId),
          connectionInfo: {
            joinedAt: new Date(),
            lastSeen: new Date(),
            deviceType: request.headers['user-agent']?.includes('Mobile') ? 'mobile' : 'desktop',
            platform: 'web'
          }
        },
        { upsert: true }
      );
      
      // إنشاء نشاط الانضمام
      await RoomActivity.createActivity(
        room._id,
        'user_joined',
        userId
      );
      
      // إنشاء رسالة انضمام في الدردشة
      const user = await User.findById(userId);
      await RoomMessage.createJoinMessage(room._id, user);
      
      reply.send({
        success: true,
        message: 'تم الانضمام للغرفة بنجاح',
        data: {
          userRole: room.getUserRole(userId),
          participantCount: room.getCurrentParticipantCount()
        }
      });
      
    } catch (error) {
      fastify.log.error(error);
      reply.status(500).send({
        success: false,
        message: 'حدث خطأ أثناء الانضمام للغرفة'
      });
    }
  });
  
  // مغادرة الغرفة
  fastify.post('/:roomId/leave', async (request, reply) => {
    try {
      const { roomId } = request.params;
      const userId = request.user.id;
      
      const room = await Room.findOne({ roomId });
      if (!room) {
        return reply.status(404).send({
          success: false,
          message: 'الغرفة غير موجودة'
        });
      }
      
      // إزالة من المقعد إذا كان موجوداً
      const wasOnMic = room.removeUserFromSeat(userId);
      let seatNumber = null;
      
      if (wasOnMic) {
        const seat = room.seats.find(s => s.userId && s.userId.toString() === userId);
        seatNumber = seat?.seatNumber;
      }
      
      // إزالة من المستمعين
      room.listeners = room.listeners.filter(l => l.userId.toString() !== userId);
      
      // إزالة من طابور الانتظار
      room.removeFromWaitingQueue(userId);
      
      room.updateLastActivity();
      await room.save();
      
      // تحديث حالة المستخدم
      await RoomUserStatus.findOneAndUpdate(
        { roomId: room._id, userId },
        { 
          status: 'offline',
          'connectionInfo.lastSeen': new Date()
        }
      );
      
      // إنشاء أنشطة المغادرة
      if (wasOnMic && seatNumber) {
        await RoomActivity.createActivity(
          room._id,
          'user_left_mic',
          userId,
          { seatInfo: { fromSeat: seatNumber } }
        );
      }
      
      await RoomActivity.createActivity(
        room._id,
        'user_left',
        userId
      );
      
      // إنشاء رسائل المغادرة
      const user = await User.findById(userId);
      
      if (wasOnMic && seatNumber) {
        await RoomMessage.createMicLeaveMessage(room._id, user, seatNumber);
      }
      
      await RoomMessage.createLeaveMessage(room._id, user);
      
      reply.send({
        success: true,
        message: 'تم مغادرة الغرفة بنجاح',
        data: {
          wasOnMic,
          seatNumber,
          participantCount: room.getCurrentParticipantCount()
        }
      });
      
    } catch (error) {
      fastify.log.error(error);
      reply.status(500).send({
        success: false,
        message: 'حدث خطأ أثناء مغادرة الغرفة'
      });
    }
  });
  
  // الحصول على قائمة الغرف النشطة
  fastify.get('/active', async (request, reply) => {
    try {
      const { category, page = 1, limit = 20 } = request.query;
      
      const filters = { status: 'active' };
      if (category && category !== 'all') {
        filters.category = category;
      }
      
      const rooms = await Room.find(filters)
        .populate('ownerId', 'displayName profilePicture')
        .sort({ lastActiveAt: -1, 'stats.peakParticipants': -1 })
        .limit(limit)
        .skip((page - 1) * limit);
      
      const roomsWithStats = rooms.map(room => ({
        _id: room._id,
        roomId: room.roomId,
        title: room.title,
        description: room.description,
        category: room.category,
        tags: room.tags,
        owner: room.ownerId,
        participantCount: room.getCurrentParticipantCount(),
        micStats: room.getMicStats(),
        isPrivate: room.settings.accessSettings.isPrivate,
        lastActiveAt: room.lastActiveAt,
        createdAt: room.createdAt
      }));
      
      reply.send({
        success: true,
        data: {
          rooms: roomsWithStats,
          pagination: {
            page: parseInt(page),
            limit: parseInt(limit),
            hasMore: rooms.length === parseInt(limit)
          }
        }
      });
      
    } catch (error) {
      fastify.log.error(error);
      reply.status(500).send({
        success: false,
        message: 'حدث خطأ أثناء جلب قائمة الغرف'
      });
    }
  });
  
}

module.exports = roomRoutes;

