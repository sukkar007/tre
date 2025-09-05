import 'dart:async';
import 'dart:math';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../models/room_message_model.dart';
import 'mock_auth_service.dart';

/// خدمة الغرف التجريبية - تعمل بدون خادم حقيقي
class MockRoomService {
  static final MockRoomService _instance = MockRoomService._internal();
  factory MockRoomService() => _instance;
  MockRoomService._internal();

  final MockAuthService _authService = MockAuthService();
  final Map<String, RoomModel> _rooms = {};
  final Map<String, List<RoomMessageModel>> _roomMessages = {};
  final Map<String, List<UserModel>> _roomUsers = {};
  
  final StreamController<List<RoomModel>> _roomsController = StreamController<List<RoomModel>>.broadcast();
  final StreamController<RoomModel?> _currentRoomController = StreamController<RoomModel?>.broadcast();
  final StreamController<List<RoomMessageModel>> _messagesController = StreamController<List<RoomMessageModel>>.broadcast();

  /// تيارات البيانات
  Stream<List<RoomModel>> get roomsStream => _roomsController.stream;
  Stream<RoomModel?> get currentRoomStream => _currentRoomController.stream;
  Stream<List<RoomMessageModel>> get messagesStream => _messagesController.stream;

  RoomModel? _currentRoom;
  RoomModel? get currentRoom => _currentRoom;

  /// تهيئة البيانات التجريبية
  void initializeDemoData() {
    _createDemoRooms();
    _createDemoMessages();
    _roomsController.add(_rooms.values.toList());
  }

  /// إنشاء غرف تجريبية
  void _createDemoRooms() {
    final demoUsers = _authService.getAllDemoUsers();
    
    // غرفة 1: غرفة عامة نشطة
    final room1 = RoomModel(
      id: 'room_001',
      name: '🎵 صالون الموسيقى العربية',
      description: 'مناقشة وتشغيل أجمل الأغاني العربية الكلاسيكية والحديثة',
      ownerId: demoUsers[0].id,
      ownerName: demoUsers[0].name,
      category: 'موسيقى',
      isPublic: true,
      maxUsers: 50,
      currentUsers: 23,
      seats: _createDemoSeats(demoUsers.take(4).toList()),
      settings: RoomSettings(
        chatEnabled: true,
        micEnabled: true,
        youtubeEnabled: true,
        musicEnabled: true,
        profanityFilter: true,
        slowMode: false,
        adminOnlyChat: false,
      ),
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    );

    // غرفة 2: غرفة خاصة للأصدقاء
    final room2 = RoomModel(
      id: 'room_002', 
      name: '👥 جلسة الأصدقاء',
      description: 'غرفة خاصة للدردشة مع الأصدقاء المقربين',
      ownerId: demoUsers[1].id,
      ownerName: demoUsers[1].name,
      category: 'اجتماعي',
      isPublic: false,
      maxUsers: 20,
      currentUsers: 8,
      seats: _createDemoSeats(demoUsers.skip(1).take(3).toList()),
      settings: RoomSettings(
        chatEnabled: true,
        micEnabled: true,
        youtubeEnabled: false,
        musicEnabled: true,
        profanityFilter: true,
        slowMode: true,
        adminOnlyChat: false,
      ),
      createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
    );

    // غرفة 3: غرفة تعليمية
    final room3 = RoomModel(
      id: 'room_003',
      name: '📚 دروس اللغة الإنجليزية',
      description: 'تعلم اللغة الإنجليزية مع مدرسين متخصصين',
      ownerId: demoUsers[3].id,
      ownerName: demoUsers[3].name,
      category: 'تعليم',
      isPublic: true,
      maxUsers: 30,
      currentUsers: 15,
      seats: _createDemoSeats([demoUsers[3], demoUsers[4]]),
      settings: RoomSettings(
        chatEnabled: true,
        micEnabled: false,
        youtubeEnabled: true,
        musicEnabled: false,
        profanityFilter: true,
        slowMode: true,
        adminOnlyChat: true,
      ),
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    );

    // غرفة 4: غرفة ألعاب
    final room4 = RoomModel(
      id: 'room_004',
      name: '🎮 نادي الألعاب',
      description: 'مناقشة أحدث الألعاب والبطولات',
      ownerId: demoUsers[2].id,
      ownerName: demoUsers[2].name,
      category: 'ألعاب',
      isPublic: true,
      maxUsers: 40,
      currentUsers: 31,
      seats: _createDemoSeats(demoUsers.take(5).toList()),
      settings: RoomSettings(
        chatEnabled: true,
        micEnabled: true,
        youtubeEnabled: true,
        musicEnabled: true,
        profanityFilter: false,
        slowMode: false,
        adminOnlyChat: false,
      ),
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
    );

    _rooms['room_001'] = room1;
    _rooms['room_002'] = room2;
    _rooms['room_003'] = room3;
    _rooms['room_004'] = room4;

    // إضافة المستخدمين للغرف
    _roomUsers['room_001'] = demoUsers.take(4).toList();
    _roomUsers['room_002'] = demoUsers.skip(1).take(3).toList();
    _roomUsers['room_003'] = [demoUsers[3], demoUsers[4]];
    _roomUsers['room_004'] = demoUsers;
  }

  /// إنشاء مقاعد تجريبية
  List<MicSeat> _createDemoSeats(List<UserModel> users) {
    final seats = <MicSeat>[];
    
    for (int i = 0; i < 8; i++) {
      if (i < users.length) {
        seats.add(MicSeat(
          seatNumber: i,
          id: 'seat_$i',
          index: i,
          userId: users[i].id,
          userName: users[i].name,
          userAvatar: users[i].avatar,
          isMuted: Random().nextBool(),
          isVIP: users[i].isVip,
          isLocked: false,
          joinedAt: DateTime.now().subtract(Duration(minutes: Random().nextInt(60))),
        ));
      } else {
        seats.add(MicSeat(
          seatNumber: i,
          id: 'seat_$i',
          index: i,
          userId: null,
          userName: null,
          userAvatar: null,
          isMuted: false,
          isVIP: i >= 6, // المقاعد الأخيرة VIP
          isLocked: false,
          joinedAt: null,
        ));
      }
    }
    
    return seats;
  }

  /// إنشاء رسائل تجريبية
  void _createDemoMessages() {
    final demoUsers = _authService.getAllDemoUsers();
    final messages = <String, List<RoomMessageModel>>{};

    // رسائل الغرفة الأولى
    messages['room_001'] = [
      RoomMessageModel(
        id: 'msg_001',
        roomId: 'room_001',
        senderId: demoUsers[0].id,
        userId: demoUsers[0].id,
        userName: demoUsers[0].name,
        userAvatar: demoUsers[0].avatar,
        content: 'أهلاً وسهلاً بكم في صالون الموسيقى! 🎵',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      RoomMessageModel(
        id: 'msg_002',
        roomId: 'room_001',
        senderId: demoUsers[1].id,
        userId: demoUsers[1].id,
        userName: demoUsers[1].name,
        userAvatar: demoUsers[1].avatar,
        content: 'شكراً لك، الغرفة رائعة! 👏',
        createdAt: DateTime.now().subtract(const Duration(minutes: 28)),
      ),
      RoomMessageModel(
        id: 'msg_003',
        roomId: 'room_001',
        senderId: demoUsers[2].id,
        userId: demoUsers[2].id,
        userName: demoUsers[2].name,
        userAvatar: demoUsers[2].avatar,
        content: 'هل يمكن تشغيل أغنية فيروز؟ 🎶',
        createdAt: DateTime.now().subtract(const Duration(minutes: 25)),
      ),
    ];

    // رسائل الغرفة الثانية
    messages['room_002'] = [
      RoomMessageModel(
        id: 'msg_004',
        roomId: 'room_002',
        senderId: demoUsers[1].id,
        userId: demoUsers[1].id,
        userName: demoUsers[1].name,
        userAvatar: demoUsers[1].avatar,
        content: 'كيف حالكم يا أصدقاء؟ 😊',
        createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
    ];

    _roomMessages.addAll(messages);
  }

  /// الحصول على قائمة الغرف
  Future<List<RoomModel>> getRooms() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _rooms.values.toList();
  }

  /// الانضمام لغرفة
  Future<RoomModel?> joinRoom(String roomId) async {
    await Future.delayed(const Duration(seconds: 1));
    
    final room = _rooms[roomId];
    if (room == null) return null;

    _currentRoom = room;
    _currentRoomController.add(_currentRoom);
    
    // إرسال رسائل الغرفة
    final messages = _roomMessages[roomId] ?? [];
    _messagesController.add(messages);
    
    return room;
  }

  /// مغادرة الغرفة
  Future<void> leaveRoom() async {
    _currentRoom = null;
    _currentRoomController.add(null);
    _messagesController.add([]);
  }

  /// إرسال رسالة
  Future<void> sendMessage(String roomId, String message) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    await Future.delayed(const Duration(milliseconds: 300));

    final newMessage = RoomMessageModel(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      roomId: roomId,
      senderId: currentUser.id,
      userId: currentUser.id,
      userName: currentUser.name,
      userAvatar: currentUser.avatar,
      content: message,
      createdAt: DateTime.now(),
    );

    _roomMessages[roomId] = _roomMessages[roomId] ?? [];
    _roomMessages[roomId]!.add(newMessage);
    
    if (_currentRoom?.id == roomId) {
      _messagesController.add(_roomMessages[roomId]!);
    }
  }

  /// طلب الانضمام لمقعد
  Future<bool> requestSeat(String roomId, int seatIndex) async {
    await Future.delayed(const Duration(milliseconds: 500));
    
    final room = _rooms[roomId];
    final currentUser = _authService.currentUser;
    if (room == null || currentUser == null) return false;

    // التحقق من توفر المقعد
    if (seatIndex >= room.seats.length) return false;
    if (room.seats[seatIndex].userId != null) return false;

    // إضافة المستخدم للمقعد
    room.seats[seatIndex] = room.seats[seatIndex].copyWith(
      userId: currentUser.id,
      userName: currentUser.name,
      userAvatar: currentUser.avatar,
      joinedAt: DateTime.now(),
    );

    _rooms[roomId] = room;
    if (_currentRoom?.id == roomId) {
      _currentRoom = room;
      _currentRoomController.add(_currentRoom);
    }

    return true;
  }

  /// مغادرة المقعد
  Future<bool> leaveSeat(String roomId, int seatIndex) async {
    await Future.delayed(const Duration(milliseconds: 300));
    
    final room = _rooms[roomId];
    if (room == null) return false;

    if (seatIndex >= room.seats.length) return false;

    // إزالة المستخدم من المقعد
    room.seats[seatIndex] = room.seats[seatIndex].copyWith(
      userId: null,
      userName: null,
      userAvatar: null,
      joinedAt: null,
      isMuted: false,
    );

    _rooms[roomId] = room;
    if (_currentRoom?.id == roomId) {
      _currentRoom = room;
      _currentRoomController.add(_currentRoom);
    }

    return true;
  }

  /// كتم/إلغاء كتم مستخدم
  Future<bool> toggleMute(String roomId, int seatIndex) async {
    await Future.delayed(const Duration(milliseconds: 200));
    
    final room = _rooms[roomId];
    if (room == null) return false;

    if (seatIndex >= room.seats.length) return false;
    if (room.seats[seatIndex].userId == null) return false;

    room.seats[seatIndex] = room.seats[seatIndex].copyWith(
      isMuted: !room.seats[seatIndex].isMuted,
    );

    _rooms[roomId] = room;
    if (_currentRoom?.id == roomId) {
      _currentRoom = room;
      _currentRoomController.add(_currentRoom);
    }

    return true;
  }

  /// الحصول على مستخدمي الغرفة
  List<UserModel> getRoomUsers(String roomId) {
    return _roomUsers[roomId] ?? [];
  }

  /// تنظيف الموارد
  void dispose() {
    _roomsController.close();
    _currentRoomController.close();
    _messagesController.close();
  }
}

/// إضافة copyWith للـ MicSeat
extension MicSeatCopyWith on MicSeat {
  MicSeat copyWith({
    int? seatNumber,
    String? userId,
    String? userName,
    String? userAvatar,
    bool? isMuted,
    bool? isVIP,
    bool? isLocked,
    DateTime? joinedAt,
  }) {
    return MicSeat(
      seatNumber: seatNumber ?? this.seatNumber,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      isMuted: isMuted ?? this.isMuted,
      isVIP: isVIP ?? this.isVIP,
      isLocked: isLocked ?? this.isLocked,
      joinedAt: joinedAt,
    );
  }
}

