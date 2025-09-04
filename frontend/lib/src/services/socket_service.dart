import 'dart:async';
import 'dart:convert';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../utils/app_constants.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  IO.Socket? _socket;
  bool _isConnected = false;
  String? _currentRoomId;
  
  // Stream Controllers للأحداث
  final StreamController<Map<String, dynamic>> _roomJoinedController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _micLayoutUpdatedController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _usersUpdateController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _micUpdateController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _newMessageController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _roomSettingsUpdateController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _errorController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _userJoinedController = 
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<Map<String, dynamic>> _userLeftController = 
      StreamController<Map<String, dynamic>>.broadcast();

  // Getters للـ Streams
  Stream<Map<String, dynamic>> get onRoomJoined => _roomJoinedController.stream;
  Stream<Map<String, dynamic>> get onMicLayoutUpdated => _micLayoutUpdatedController.stream;
  Stream<Map<String, dynamic>> get onUsersUpdate => _usersUpdateController.stream;
  Stream<Map<String, dynamic>> get onMicUpdate => _micUpdateController.stream;
  Stream<Map<String, dynamic>> get onNewMessage => _newMessageController.stream;
  Stream<Map<String, dynamic>> get onRoomSettingsUpdate => _roomSettingsUpdateController.stream;
  Stream<Map<String, dynamic>> get onError => _errorController.stream;
  Stream<Map<String, dynamic>> get onUserJoined => _userJoinedController.stream;
  Stream<Map<String, dynamic>> get onUserLeft => _userLeftController.stream;

  bool get isConnected => _isConnected;
  String? get currentRoomId => _currentRoomId;

  // الاتصال بالخادم
  Future<void> connect(String token) async {
    try {
      if (_socket != null && _isConnected) {
        return; // مُتصل بالفعل
      }

      _socket = IO.io(
        AppConstants.socketUrl,
        IO.OptionBuilder()
            .setTransports(['websocket'])
            .enableAutoConnect()
            .setAuth({'token': token})
            .build(),
      );

      _setupEventListeners();

      // انتظار الاتصال
      final completer = Completer<void>();
      
      _socket!.onConnect((_) {
        print('Socket connected successfully');
        _isConnected = true;
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      _socket!.onConnectError((error) {
        print('Socket connection error: $error');
        _isConnected = false;
        if (!completer.isCompleted) {
          completer.completeError('فشل في الاتصال: $error');
        }
      });

      _socket!.onDisconnect((_) {
        print('Socket disconnected');
        _isConnected = false;
        _currentRoomId = null;
      });

      _socket!.connect();
      
      // انتظار الاتصال لمدة 10 ثواني كحد أقصى
      await completer.future.timeout(
        Duration(seconds: 10),
        onTimeout: () {
          throw 'انتهت مهلة الاتصال';
        },
      );

    } catch (error) {
      print('Error connecting to socket: $error');
      _isConnected = false;
      rethrow;
    }
  }

  // إعداد مستمعي الأحداث
  void _setupEventListeners() {
    if (_socket == null) return;

    // الانضمام للغرفة
    _socket!.on('room_joined', (data) {
      print('Room joined: $data');
      _roomJoinedController.add(Map<String, dynamic>.from(data));
    });

    // تحديث تخطيط المايكات
    _socket!.on('mic_layout_updated', (data) {
      print('Mic layout updated: $data');
      _micLayoutUpdatedController.add(Map<String, dynamic>.from(data));
    });

    // تحديث المستخدمين
    _socket!.on('users_update', (data) {
      print('Users update: $data');
      _usersUpdateController.add(Map<String, dynamic>.from(data));
    });

    // تحديث المايكات
    _socket!.on('mic_update', (data) {
      print('Mic update: $data');
      _micUpdateController.add(Map<String, dynamic>.from(data));
    });

    // رسالة جديدة
    _socket!.on('new_message', (data) {
      print('New message: $data');
      _newMessageController.add(Map<String, dynamic>.from(data));
    });

    // تحديث إعدادات الغرفة
    _socket!.on('room_settings_updated', (data) {
      print('Room settings updated: $data');
      _roomSettingsUpdateController.add(Map<String, dynamic>.from(data));
    });

    // انضمام مستخدم
    _socket!.on('user_joined', (data) {
      print('User joined: $data');
      _userJoinedController.add(Map<String, dynamic>.from(data));
    });

    // مغادرة مستخدم
    _socket!.on('user_left', (data) {
      print('User left: $data');
      _userLeftController.add(Map<String, dynamic>.from(data));
    });

    // أخطاء
    _socket!.on('error', (data) {
      print('Socket error: $data');
      _errorController.add(Map<String, dynamic>.from(data));
    });

    // قطع الاتصال
    _socket!.on('disconnect', (reason) {
      print('Socket disconnected: $reason');
      _isConnected = false;
      _currentRoomId = null;
    });
  }

  // الانضمام لغرفة
  Future<void> joinRoom(String roomId) async {
    if (!_isConnected || _socket == null) {
      throw 'غير متصل بالخادم';
    }

    _currentRoomId = roomId;
    _socket!.emit('join_room', {'roomId': roomId});
  }

  // مغادرة الغرفة
  Future<void> leaveRoom(String roomId) async {
    if (!_isConnected || _socket == null) {
      return;
    }

    _socket!.emit('leave_room', {'roomId': roomId});
    _currentRoomId = null;
  }

  // إرسال رسالة
  Future<void> sendMessage(String roomId, String message, {String? replyTo}) async {
    if (!_isConnected || _socket == null) {
      throw 'غير متصل بالخادم';
    }

    _socket!.emit('send_message', {
      'roomId': roomId,
      'message': message,
      'replyTo': replyTo,
    });
  }

  // طلب الانتقال للمايك
  Future<void> requestMic(String roomId, int seatNumber) async {
    if (!_isConnected || _socket == null) {
      throw 'غير متصل بالخادم';
    }

    _socket!.emit('request_mic', {
      'roomId': roomId,
      'seatNumber': seatNumber,
    });
  }

  // مغادرة المايك
  Future<void> leaveMic(String roomId) async {
    if (!_isConnected || _socket == null) {
      throw 'غير متصل بالخادم';
    }

    _socket!.emit('leave_mic', {
      'roomId': roomId,
    });
  }

  // كتم/إلغاء كتم مستخدم
  Future<void> toggleUserMute(String roomId, String userId, bool mute) async {
    if (!_isConnected || _socket == null) {
      throw 'غير متصل بالخادم';
    }

    _socket!.emit('toggle_user_mute', {
      'roomId': roomId,
      'userId': userId,
      'mute': mute,
    });
  }

  // إنزال مستخدم من المايك
  Future<void> removeUserFromMic(String roomId, String userId) async {
    if (!_isConnected || _socket == null) {
      throw 'غير متصل بالخادم';
    }

    _socket!.emit('remove_user_from_mic', {
      'roomId': roomId,
      'userId': userId,
    });
  }

  // طرد مستخدم
  Future<void> kickUser(String roomId, String userId, {String? reason}) async {
    if (!_isConnected || _socket == null) {
      throw 'غير متصل بالخادم';
    }

    _socket!.emit('kick_user', {
      'roomId': roomId,
      'userId': userId,
      'reason': reason,
    });
  }

  // تعيين مدير
  Future<void> assignAdmin(String roomId, String userId) async {
    if (!_isConnected || _socket == null) {
      throw 'غير متصل بالخادم';
    }

    _socket!.emit('assign_admin', {
      'roomId': roomId,
      'userId': userId,
    });
  }

  // إزالة مدير
  Future<void> removeAdmin(String roomId, String userId) async {
    if (!_isConnected || _socket == null) {
      throw 'غير متصل بالخادم';
    }

    _socket!.emit('remove_admin', {
      'roomId': roomId,
      'userId': userId,
    });
  }

  // تغيير عدد المايكات
  Future<void> changeMicCount(String roomId, int newCount) async {
    if (!_isConnected || _socket == null) {
      throw 'غير متصل بالخادم';
    }

    _socket!.emit('change_mic_count', {
      'roomId': roomId,
      'newCount': newCount,
    });
  }

  // تحديث إعدادات الدردشة
  Future<void> updateChatSettings(String roomId, Map<String, dynamic> settings) async {
    if (!_isConnected || _socket == null) {
      throw 'غير متصل بالخادم';
    }

    _socket!.emit('update_chat_settings', {
      'roomId': roomId,
      'settings': settings,
    });
  }

  // تحديث إعدادات الوسائط
  Future<void> updateMediaSettings(String roomId, Map<String, dynamic> settings) async {
    if (!_isConnected || _socket == null) {
      throw 'غير متصل بالخادم';
    }

    _socket!.emit('update_media_settings', {
      'roomId': roomId,
      'settings': settings,
    });
  }

  // تشغيل فيديو يوتيوب
  Future<void> playYouTubeVideo(String roomId, String videoUrl) async {
    if (!_isConnected || _socket == null) {
      throw 'غير متصل بالخادم';
    }

    _socket!.emit('play_youtube_video', {
      'roomId': roomId,
      'videoUrl': videoUrl,
    });
  }

  // إيقاف فيديو يوتيوب
  Future<void> stopYouTubeVideo(String roomId) async {
    if (!_isConnected || _socket == null) {
      throw 'غير متصل بالخادم';
    }

    _socket!.emit('stop_youtube_video', {
      'roomId': roomId,
    });
  }

  // تشغيل موسيقى
  Future<void> playMusic(String roomId, String musicUrl, String title) async {
    if (!_isConnected || _socket == null) {
      throw 'غير متصل بالخادم';
    }

    _socket!.emit('play_music', {
      'roomId': roomId,
      'musicUrl': musicUrl,
      'title': title,
    });
  }

  // إيقاف الموسيقى
  Future<void> stopMusic(String roomId) async {
    if (!_isConnected || _socket == null) {
      throw 'غير متصل بالخادم';
    }

    _socket!.emit('stop_music', {
      'roomId': roomId,
    });
  }

  // تحديث حالة المستخدم
  Future<void> updateUserStatus(String status) async {
    if (!_isConnected || _socket == null) {
      return;
    }

    _socket!.emit('update_status', {
      'status': status,
    });
  }

  // دعوة مستخدم
  Future<void> inviteUser(String roomId, String userId) async {
    if (!_isConnected || _socket == null) {
      throw 'غير متصل بالخادم';
    }

    _socket!.emit('invite_user', {
      'roomId': roomId,
      'userId': userId,
    });
  }

  // قبول دعوة
  Future<void> acceptInvitation(String roomId, String invitationId) async {
    if (!_isConnected || _socket == null) {
      throw 'غير متصل بالخادم';
    }

    _socket!.emit('accept_invitation', {
      'roomId': roomId,
      'invitationId': invitationId,
    });
  }

  // رفض دعوة
  Future<void> declineInvitation(String roomId, String invitationId) async {
    if (!_isConnected || _socket == null) {
      throw 'غير متصل بالخادم';
    }

    _socket!.emit('decline_invitation', {
      'roomId': roomId,
      'invitationId': invitationId,
    });
  }

  // إضافة مستمع للأحداث
  void onRoomJoined(Function(Map<String, dynamic>) callback) {
    onRoomJoined.listen(callback);
  }

  void onMicLayoutUpdated(Function(Map<String, dynamic>) callback) {
    onMicLayoutUpdated.listen(callback);
  }

  void onUsersUpdate(Function(Map<String, dynamic>) callback) {
    onUsersUpdate.listen(callback);
  }

  void onMicUpdate(Function(Map<String, dynamic>) callback) {
    onMicUpdate.listen(callback);
  }

  void onNewMessage(Function(Map<String, dynamic>) callback) {
    onNewMessage.listen(callback);
  }

  void onRoomSettingsUpdate(Function(Map<String, dynamic>) callback) {
    onRoomSettingsUpdate.listen(callback);
  }

  void onError(Function(Map<String, dynamic>) callback) {
    onError.listen(callback);
  }

  void onUserJoined(Function(Map<String, dynamic>) callback) {
    onUserJoined.listen(callback);
  }

  void onUserLeft(Function(Map<String, dynamic>) callback) {
    onUserLeft.listen(callback);
  }

  // قطع الاتصال
  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket = null;
    }
    _isConnected = false;
    _currentRoomId = null;
  }

  // تنظيف الموارد
  void dispose() {
    disconnect();
    _roomJoinedController.close();
    _micLayoutUpdatedController.close();
    _usersUpdateController.close();
    _micUpdateController.close();
    _newMessageController.close();
    _roomSettingsUpdateController.close();
    _errorController.close();
    _userJoinedController.close();
    _userLeftController.close();
  }
}

