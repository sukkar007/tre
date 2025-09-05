import 'dart:async';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../models/room_message_model.dart';

class MockRoomService {
  static final MockRoomService _instance = MockRoomService._internal();
  factory MockRoomService() => _instance;
  MockRoomService._internal();

  final Map<String, RoomModel> _rooms = {};
  final Map<String, List<RoomMessageModel>> _roomMessages = {};
  final StreamController<List<RoomModel>> _roomsController = StreamController<List<RoomModel>>.broadcast();
  final StreamController<List<RoomMessageModel>> _messagesController = StreamController<List<RoomMessageModel>>.broadcast();

  Stream<List<RoomModel>> get roomsStream => _roomsController.stream;
  Stream<List<RoomMessageModel>> get messagesStream => _messagesController.stream;

  // بيانات المستخدمين التجريبية
  final List<UserModel> demoUsers = [
    UserModel(
      userId: 'user_001',
      displayName: 'أحمد محمد',
      email: 'ahmed@example.com',
      photoURL: 'https://i.pravatar.cc/150?img=1',
      isOnline: true,
      isVip: true,
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    ),
    UserModel(
      userId: 'user_002',
      displayName: 'فاطمة علي',
      email: 'fatima@example.com',
      photoURL: 'https://i.pravatar.cc/150?img=2',
      isOnline: true,
      isVip: false,
      createdAt: DateTime.now().subtract(const Duration(days: 25)),
    ),
    UserModel(
      userId: 'user_003',
      displayName: 'محمد حسن',
      email: 'mohammed@example.com',
      photoURL: 'https://i.pravatar.cc/150?img=3',
      isOnline: false,
      isVip: true,
      createdAt: DateTime.now().subtract(const Duration(days: 20)),
    ),
    UserModel(
      userId: 'user_004',
      displayName: 'نور الدين',
      email: 'nour@example.com',
      photoURL: 'https://i.pravatar.cc/150?img=4',
      isOnline: true,
      isVip: false,
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
    ),
    UserModel(
      userId: 'user_005',
      displayName: 'ليلى أحمد',
      email: 'layla@example.com',
      photoURL: 'https://i.pravatar.cc/150?img=5',
      isOnline: true,
      isVip: false,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
  ];

  void initializeDemoData() {
    _initializeRooms();
    _initializeMessages();
  }

  void _initializeRooms() {
    // غرفة 1: غرفة عامة نشطة
    final room1 = RoomModel(
      id: 'room_001',
      roomId: 'room_001',
      title: '🎵 صالون الموسيقى العربية',
      description: 'مناقشة وتشغيل أجمل الأغاني العربية الكلاسيكية والحديثة',
      category: 'موسيقى',
      tags: ['موسيقى', 'عربي', 'كلاسيكي'],
      owner: demoUsers[0],
      seats: _createDemoSeats(demoUsers.take(4).toList()),
      micCount: 6,
      settings: RoomSettings(
        chatSettings: ChatSettings(
          isEnabled: true,
          profanityFilterEnabled: true,
          slowModeEnabled: false,
          slowModeInterval: 5,
          adminOnlyMode: false,
        ),
        micSettings: MicSettings(
          totalMics: 6,
          vipMics: 1,
          guestMics: 5,
          autoMuteNewSpeakers: false,
          requirePermissionToSpeak: false,
        ),
        mediaSettings: MediaSettings(
          youtubeEnabled: true,
          musicEnabled: true,
          soundEffectsEnabled: true,
          masterVolume: 1.0,
          musicVolume: 0.7,
          effectsVolume: 0.5,
        ),
        accessSettings: AccessSettings(
          isPrivate: false,
          requireApproval: false,
          maxParticipants: 50,
          allowedCountries: [],
          minAge: 13,
        ),
      ),
      stats: RoomStats(
        totalJoins: 150,
        totalMessages: 1200,
        peakParticipants: 45,
        currentParticipants: 23,
        totalDuration: const Duration(hours: 48),
        categoryStats: {'موسيقى': 100, 'دردشة': 50},
      ),
      admins: [demoUsers[1]],
      bannedUsers: [],
      waitingQueue: [],
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      lastActiveAt: DateTime.now(),
      status: 'active',
    );

    // غرفة 2: غرفة خاصة للأصدقاء
    final room2 = RoomModel(
      id: 'room_002',
      roomId: 'room_002',
      title: '👥 جلسة الأصدقاء',
      description: 'غرفة خاصة للدردشة مع الأصدقاء المقربين',
      category: 'اجتماعي',
      tags: ['أصدقاء', 'دردشة', 'خاص'],
      owner: demoUsers[1],
      seats: _createDemoSeats(demoUsers.skip(1).take(3).toList()),
      micCount: 4,
      settings: RoomSettings(
        chatSettings: ChatSettings(
          isEnabled: true,
          profanityFilterEnabled: false,
          slowModeEnabled: false,
          slowModeInterval: 5,
          adminOnlyMode: false,
        ),
        micSettings: MicSettings(
          totalMics: 4,
          vipMics: 0,
          guestMics: 4,
          autoMuteNewSpeakers: false,
          requirePermissionToSpeak: false,
        ),
        mediaSettings: MediaSettings(
          youtubeEnabled: false,
          musicEnabled: false,
          soundEffectsEnabled: true,
          masterVolume: 1.0,
          musicVolume: 0.7,
          effectsVolume: 0.5,
        ),
        accessSettings: AccessSettings(
          isPrivate: true,
          requireApproval: true,
          maxParticipants: 20,
          allowedCountries: [],
          minAge: 18,
        ),
      ),
      stats: RoomStats(
        totalJoins: 25,
        totalMessages: 180,
        peakParticipants: 12,
        currentParticipants: 8,
        totalDuration: const Duration(hours: 12),
        categoryStats: {'دردشة': 25},
      ),
      admins: [],
      bannedUsers: [],
      waitingQueue: [],
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      lastActiveAt: DateTime.now().subtract(const Duration(minutes: 5)),
      status: 'active',
    );

    _rooms['room_001'] = room1;
    _rooms['room_002'] = room2;

    _roomsController.add(_rooms.values.toList());
  }

  List<MicSeat> _createDemoSeats(List<UserModel> users) {
    final seats = <MicSeat>[];
    
    for (int i = 0; i < 6; i++) {
      if (i < users.length) {
        seats.add(MicSeat(
          seatNumber: i + 1,
          userId: users[i].id,
          user: users[i],
          isVIP: users[i].isVip,
          isMuted: false,
          isLocked: false,
          joinedAt: DateTime.now().subtract(Duration(minutes: 30 - (i * 5))),
        ));
      } else {
        seats.add(MicSeat(
          seatNumber: i + 1,
          userId: null,
          user: null,
          isVIP: i == 0,
          isMuted: false,
          isLocked: false,
          joinedAt: null,
        ));
      }
    }
    
    return seats;
  }

  void _initializeMessages() {
    final messages = <String, List<RoomMessageModel>>{};

    // رسائل الغرفة الأولى
    messages['room_001'] = [
      RoomMessageModel(
        id: 'msg_001',
        roomId: 'room_001',
        senderId: demoUsers[0].id,
        senderName: demoUsers[0].name,
        senderRole: 'host',
        messageType: 'text',
        userId: demoUsers[0].id,
        userName: demoUsers[0].name,
        userAvatar: demoUsers[0].avatar,
        content: 'أهلاً وسهلاً بكم في صالون الموسيقى! 🎵',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        isDeleted: false,
        reactions: [],
      ),
      RoomMessageModel(
        id: 'msg_002',
        roomId: 'room_001',
        senderId: demoUsers[1].id,
        senderName: demoUsers[1].name,
        senderRole: 'member',
        messageType: 'text',
        userId: demoUsers[1].id,
        userName: demoUsers[1].name,
        userAvatar: demoUsers[1].avatar,
        content: 'شكراً لك، الغرفة رائعة! 👏',
        createdAt: DateTime.now().subtract(const Duration(minutes: 28)),
        isDeleted: false,
        reactions: [],
      ),
      RoomMessageModel(
        id: 'msg_003',
        roomId: 'room_001',
        senderId: demoUsers[2].id,
        senderName: demoUsers[2].name,
        senderRole: 'member',
        messageType: 'text',
        userId: demoUsers[2].id,
        userName: demoUsers[2].name,
        userAvatar: demoUsers[2].avatar,
        content: 'هل يمكن تشغيل أغنية فيروز؟ 🎶',
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
        isDeleted: false,
        reactions: [],
      ),
    ];

    // رسائل الغرفة الثانية
    messages['room_002'] = [
      RoomMessageModel(
        id: 'msg_004',
        roomId: 'room_002',
        senderId: demoUsers[1].id,
        senderName: demoUsers[1].name,
        senderRole: 'member',
        messageType: 'text',
        userId: demoUsers[1].id,
        userName: demoUsers[1].name,
        userAvatar: demoUsers[1].avatar,
        content: 'كيف حالكم يا أصدقاء؟ 😊',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
        isDeleted: false,
        reactions: [],
      ),
    ];

    _roomMessages.addAll(messages);
  }

  // الحصول على قائمة الغرف
  Future<List<RoomModel>> getRooms() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _rooms.values.toList();
  }

  // الحصول على غرفة محددة
  Future<RoomModel?> getRoom(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _rooms[roomId];
  }

  // الحصول على رسائل غرفة
  Future<List<RoomMessageModel>> getRoomMessages(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return _roomMessages[roomId] ?? [];
  }

  // إرسال رسالة
  Future<void> sendMessage(String roomId, String message) async {
    final currentUser = demoUsers[0]; // المستخدم الحالي
    if (currentUser == null) return;

    await Future.delayed(const Duration(milliseconds: 300));

    final newMessage = RoomMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      roomId: roomId,
      senderId: currentUser.id,
      senderName: currentUser.name,
      senderRole: 'member',
      messageType: 'text',
      userId: currentUser.id,
      userName: currentUser.name,
      userAvatar: currentUser.avatar,
      content: message,
      createdAt: DateTime.now(),
      isDeleted: false,
      reactions: [],
    );

    _roomMessages[roomId] = _roomMessages[roomId] ?? [];
    _roomMessages[roomId]!.add(newMessage);
    
    _messagesController.add(_roomMessages[roomId]!);
  }

  // الانضمام إلى غرفة
  Future<bool> joinRoom(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final room = _rooms[roomId];
    if (room == null) return false;

    // محاكاة نجاح الانضمام
    return true;
  }

  // مغادرة غرفة
  Future<void> leaveRoom(String roomId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // محاكاة مغادرة الغرفة
  }

  // البحث في الغرف
  Future<List<RoomModel>> searchRooms(String query) async {
    await Future.delayed(const Duration(milliseconds: 400));
    
    if (query.isEmpty) return _rooms.values.toList();
    
    return _rooms.values.where((room) {
      return room.title.toLowerCase().contains(query.toLowerCase()) ||
             room.description?.toLowerCase().contains(query.toLowerCase()) == true ||
             room.category.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  // تنظيف الموارد
  void dispose() {
    _roomsController.close();
    _messagesController.close();
  }
}

