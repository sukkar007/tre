import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:zego_express_engine/zego_express_engine.dart';
import 'package:zego_uikit/zego_uikit.dart';
import '../config/zego_config.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';

/// خدمة ZegoCloud للتحكم في الصوت والغرف الصوتية
class ZegoAudioService {
  static final ZegoAudioService _instance = ZegoAudioService._internal();
  factory ZegoAudioService() => _instance;
  ZegoAudioService._internal();

  // متحكمات الأحداث
  final StreamController<ZegoRoomState> _roomStateController = StreamController.broadcast();
  final StreamController<List<ZegoUIKitUser>> _usersController = StreamController.broadcast();
  final StreamController<Map<String, bool>> _micStatesController = StreamController.broadcast();
  final StreamController<String> _messagesController = StreamController.broadcast();

  // الحالة الحالية
  ZegoRoomState _currentRoomState = ZegoRoomState.disconnected;
  String? _currentRoomID;
  String? _currentUserID;
  bool _isInitialized = false;
  bool _isMicrophoneOn = false;
  bool _isSpeakerOn = true;

  // Getters للأحداث
  Stream<ZegoRoomState> get roomStateStream => _roomStateController.stream;
  Stream<List<ZegoUIKitUser>> get usersStream => _usersController.stream;
  Stream<Map<String, bool>> get micStatesStream => _micStatesController.stream;
  Stream<String> get messagesStream => _messagesController.stream;

  // Getters للحالة
  ZegoRoomState get currentRoomState => _currentRoomState;
  String? get currentRoomID => _currentRoomID;
  String? get currentUserID => _currentUserID;
  bool get isInitialized => _isInitialized;
  bool get isMicrophoneOn => _isMicrophoneOn;
  bool get isSpeakerOn => _isSpeakerOn;

  /// تهيئة ZegoCloud SDK
  Future<bool> initialize() async {
    try {
      if (!ZegoConfig.isConfigValid()) {
        developer.log('ZegoCloud config is invalid', name: 'ZegoAudioService');
        return false;
      }

      // تهيئة ZegoUIKit
      await ZegoUIKit().init(
        appID: ZegoConfig.appID,
        appSign: ZegoConfig.appSign,
      );

      // تهيئة ZegoExpressEngine
      await ZegoExpressEngine.createEngineWithProfile(ZegoEngineProfile(
        ZegoConfig.appID,
        ZegoScenario.Communication,
        appSign: ZegoConfig.appSign,
      ));

      // تسجيل مستمعي الأحداث
      _registerEventListeners();

      _isInitialized = true;
      developer.log('ZegoCloud initialized successfully', name: 'ZegoAudioService');
      return true;
    } catch (e) {
      developer.log('Failed to initialize ZegoCloud: $e', name: 'ZegoAudioService');
      return false;
    }
  }

  /// تسجيل مستمعي الأحداث
  void _registerEventListeners() {
    // حالة الغرفة
    ZegoExpressEngine.onRoomStateChanged = (String roomID, ZegoRoomStateChangedReason reason, int errorCode, Map<String, dynamic> extendedData) {
      developer.log('Room state changed: $roomID, reason: $reason, error: $errorCode', name: 'ZegoAudioService');
      
      switch (reason) {
        case ZegoRoomStateChangedReason.Logining:
          _updateRoomState(ZegoRoomState.connecting);
          break;
        case ZegoRoomStateChangedReason.Logined:
          _updateRoomState(ZegoRoomState.connected);
          break;
        case ZegoRoomStateChangedReason.LoginFailed:
        case ZegoRoomStateChangedReason.Logouted:
          _updateRoomState(ZegoRoomState.disconnected);
          break;
        case ZegoRoomStateChangedReason.Reconnecting:
          _updateRoomState(ZegoRoomState.reconnecting);
          break;
      }
    };

    // المستخدمون
    ZegoExpressEngine.onRoomUserUpdate = (String roomID, ZegoUpdateType updateType, List<ZegoUser> userList) {
      developer.log('Room users updated: $roomID, type: $updateType, users: ${userList.length}', name: 'ZegoAudioService');
      _updateUsersList();
    };

    // حالة المايك
    ZegoExpressEngine.onRemoteMicStateUpdate = (String streamID, ZegoRemoteDeviceState state) {
      developer.log('Remote mic state updated: $streamID, state: $state', name: 'ZegoAudioService');
      _updateMicStates();
    };

    // الرسائل
    ZegoExpressEngine.onIMRecvBroadcastMessage = (String roomID, List<ZegoBroadcastMessageInfo> messageList) {
      for (var message in messageList) {
        _messagesController.add('${message.fromUser.userName}: ${message.message}');
      }
    };

    // جودة الشبكة
    ZegoExpressEngine.onNetworkQuality = (String userID, ZegoStreamQualityLevel upstreamQuality, ZegoStreamQualityLevel downstreamQuality) {
      // يمكن استخدامها لعرض مؤشر جودة الاتصال
    };
  }

  /// الانضمام إلى غرفة صوتية
  Future<bool> joinRoom({
    required String roomID,
    required UserModel user,
    required String userRole, // 'host', 'speaker', 'audience'
  }) async {
    try {
      if (!_isInitialized) {
        developer.log('ZegoCloud not initialized', name: 'ZegoAudioService');
        return false;
      }

      _currentRoomID = roomID;
      _currentUserID = user.id;

      // إعداد معلومات المستخدم
      final zegoUser = ZegoUser(user.id, user.displayName);
      
      // الانضمام إلى الغرفة
      final result = await ZegoExpressEngine.instance.loginRoom(
        roomID,
        zegoUser,
        config: ZegoRoomConfig.defaultConfig(),
      );

      if (result.errorCode == 0) {
        // تحديد دور المستخدم
        await _setUserRole(userRole);
        
        developer.log('Successfully joined room: $roomID', name: 'ZegoAudioService');
        return true;
      } else {
        developer.log('Failed to join room: ${result.errorCode}', name: 'ZegoAudioService');
        return false;
      }
    } catch (e) {
      developer.log('Error joining room: $e', name: 'ZegoAudioService');
      return false;
    }
  }

  /// مغادرة الغرفة الصوتية
  Future<void> leaveRoom() async {
    try {
      if (_currentRoomID != null) {
        // إيقاف البث إذا كان نشطاً
        await stopPublishing();
        
        // مغادرة الغرفة
        await ZegoExpressEngine.instance.logoutRoom(_currentRoomID!);
        
        _currentRoomID = null;
        _currentUserID = null;
        _updateRoomState(ZegoRoomState.disconnected);
        
        developer.log('Left room successfully', name: 'ZegoAudioService');
      }
    } catch (e) {
      developer.log('Error leaving room: $e', name: 'ZegoAudioService');
    }
  }

  /// تحديد دور المستخدم
  Future<void> _setUserRole(String role) async {
    try {
      switch (role) {
        case 'host':
        case 'speaker':
          // المتحدثون يمكنهم البث
          await startPublishing();
          break;
        case 'audience':
          // المستمعون لا يبثون
          await stopPublishing();
          break;
      }
    } catch (e) {
      developer.log('Error setting user role: $e', name: 'ZegoAudioService');
    }
  }

  /// بدء البث الصوتي (للمتحدثين)
  Future<bool> startPublishing() async {
    try {
      if (_currentUserID == null) return false;

      final streamID = 'stream_$_currentUserID';
      await ZegoExpressEngine.instance.startPublishingStream(streamID);
      
      developer.log('Started publishing stream: $streamID', name: 'ZegoAudioService');
      return true;
    } catch (e) {
      developer.log('Error starting publishing: $e', name: 'ZegoAudioService');
      return false;
    }
  }

  /// إيقاف البث الصوتي
  Future<void> stopPublishing() async {
    try {
      await ZegoExpressEngine.instance.stopPublishingStream();
      developer.log('Stopped publishing stream', name: 'ZegoAudioService');
    } catch (e) {
      developer.log('Error stopping publishing: $e', name: 'ZegoAudioService');
    }
  }

  /// تشغيل/إيقاف المايك
  Future<void> toggleMicrophone() async {
    try {
      _isMicrophoneOn = !_isMicrophoneOn;
      await ZegoExpressEngine.instance.muteMicrophone(!_isMicrophoneOn);
      
      developer.log('Microphone ${_isMicrophoneOn ? 'enabled' : 'disabled'}', name: 'ZegoAudioService');
      _updateMicStates();
    } catch (e) {
      developer.log('Error toggling microphone: $e', name: 'ZegoAudioService');
    }
  }

  /// تشغيل/إيقاف السماعة
  Future<void> toggleSpeaker() async {
    try {
      _isSpeakerOn = !_isSpeakerOn;
      await ZegoExpressEngine.instance.muteSpeaker(!_isSpeakerOn);
      
      developer.log('Speaker ${_isSpeakerOn ? 'enabled' : 'disabled'}', name: 'ZegoAudioService');
    } catch (e) {
      developer.log('Error toggling speaker: $e', name: 'ZegoAudioService');
    }
  }

  /// كتم/إلغاء كتم مستخدم آخر (للمدراء فقط)
  Future<bool> muteUser(String userID, bool mute) async {
    try {
      // هذه الوظيفة تتطلب صلاحيات إدارية
      // يجب تنفيذها من خلال الخادم أو ZegoCloud Console
      
      developer.log('${mute ? 'Muting' : 'Unmuting'} user: $userID', name: 'ZegoAudioService');
      
      // إرسال طلب إلى الخادم لكتم المستخدم
      // await _sendMuteRequest(userID, mute);
      
      return true;
    } catch (e) {
      developer.log('Error ${mute ? 'muting' : 'unmuting'} user: $e', name: 'ZegoAudioService');
      return false;
    }
  }

  /// إرسال رسالة في الغرفة
  Future<bool> sendMessage(String message) async {
    try {
      if (_currentRoomID == null) return false;

      await ZegoExpressEngine.instance.sendBroadcastMessage(_currentRoomID!, message);
      
      developer.log('Message sent: $message', name: 'ZegoAudioService');
      return true;
    } catch (e) {
      developer.log('Error sending message: $e', name: 'ZegoAudioService');
      return false;
    }
  }

  /// تحديث حالة الغرفة
  void _updateRoomState(ZegoRoomState newState) {
    _currentRoomState = newState;
    _roomStateController.add(newState);
  }

  /// تحديث قائمة المستخدمين
  void _updateUsersList() {
    // الحصول على قائمة المستخدمين من ZegoUIKit
    final users = ZegoUIKit().getAllUsers();
    _usersController.add(users);
  }

  /// تحديث حالات المايكات
  void _updateMicStates() {
    final micStates = <String, bool>{};
    final users = ZegoUIKit().getAllUsers();
    
    for (var user in users) {
      micStates[user.id] = user.microphone.value;
    }
    
    _micStatesController.add(micStates);
  }

  /// تنظيف الموارد
  Future<void> dispose() async {
    try {
      await leaveRoom();
      await ZegoExpressEngine.destroyEngine();
      
      _roomStateController.close();
      _usersController.close();
      _micStatesController.close();
      _messagesController.close();
      
      _isInitialized = false;
      developer.log('ZegoAudioService disposed', name: 'ZegoAudioService');
    } catch (e) {
      developer.log('Error disposing ZegoAudioService: $e', name: 'ZegoAudioService');
    }
  }

  /// الحصول على معلومات جودة الصوت
  Map<String, dynamic> getAudioQualityInfo() {
    return {
      'microphoneOn': _isMicrophoneOn,
      'speakerOn': _isSpeakerOn,
      'roomState': _currentRoomState.toString(),
      'roomID': _currentRoomID,
      'userID': _currentUserID,
    };
  }

  /// تحديث إعدادات الصوت
  Future<void> updateAudioSettings({
    bool? enableEchoCancellation,
    bool? enableNoiseSuppression,
    bool? enableAutoGainControl,
    String? audioQuality,
  }) async {
    try {
      if (enableEchoCancellation != null) {
        await ZegoExpressEngine.instance.enableAEC(enableEchoCancellation);
      }
      
      if (enableNoiseSuppression != null) {
        await ZegoExpressEngine.instance.enableANS(enableNoiseSuppression);
      }
      
      if (enableAutoGainControl != null) {
        await ZegoExpressEngine.instance.enableAGC(enableAutoGainControl);
      }
      
      if (audioQuality != null) {
        Map<String, dynamic> config;
        switch (audioQuality) {
          case 'high':
            config = ZegoAudioSettings.highQuality;
            break;
          case 'medium':
            config = ZegoAudioSettings.mediumQuality;
            break;
          case 'low':
            config = ZegoAudioSettings.lowQuality;
            break;
          default:
            config = ZegoAudioSettings.mediumQuality;
        }
        
        await ZegoExpressEngine.instance.setAudioConfig(ZegoAudioConfig(
          bitrate: config['bitrate'],
          channel: config['channels'] == 2 ? ZegoAudioChannel.Stereo : ZegoAudioChannel.Mono,
          codecID: ZegoAudioCodecID.Normal,
        ));
      }
      
      developer.log('Audio settings updated', name: 'ZegoAudioService');
    } catch (e) {
      developer.log('Error updating audio settings: $e', name: 'ZegoAudioService');
    }
  }
}

