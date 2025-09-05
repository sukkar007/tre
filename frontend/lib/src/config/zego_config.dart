/// إعدادات ZegoCloud للغرف الصوتية
class ZegoConfig {
  // معرف التطبيق من ZegoCloud Console
  // يجب الحصول عليه من: https://console.zegocloud.com/
  static const int appID = 123456789; // استبدل بـ App ID الحقيقي
  
  // مفتاح التطبيق من ZegoCloud Console
  static const String appSign = "your_app_sign_here"; // استبدل بـ App Sign الحقيقي
  
  // إعدادات الخادم (اختياري للاستخدام المتقدم)
  static const String serverUrl = "https://your-server.com";
  
  // إعدادات الصوت الافتراضية
  static const Map<String, dynamic> audioConfig = {
    'enableMicrophone': true,
    'enableSpeaker': true,
    'enableAudioMixing': true,
    'audioQuality': 'high', // low, medium, high
    'enableEchoCancellation': true,
    'enableNoiseSuppression': true,
    'enableAutoGainControl': true,
  };
  
  // إعدادات الغرفة الافتراضية
  static const Map<String, dynamic> roomConfig = {
    'maxUsers': 20,
    'enableChat': true,
    'enableUserList': true,
    'enableMicrophoneControl': true,
    'enableSpeakerControl': true,
  };
  
  // أدوار المستخدمين في ZegoCloud
  static const Map<String, int> userRoles = {
    'host': 1,      // مالك الغرفة
    'speaker': 2,   // متحدث (على المايك)
    'audience': 3,  // مستمع
  };
  
  // إعدادات UI
  static const Map<String, dynamic> uiConfig = {
    'showMemberList': true,
    'showChatButton': true,
    'showLeaveButton': true,
    'showMicrophoneButton': true,
    'showSpeakerButton': true,
    'enableTextMessage': true,
    'enableUserAvatarVisible': true,
  };
  
  /// التحقق من صحة الإعدادات
  static bool isConfigValid() {
    return appID != 123456789 && appSign != "your_app_sign_here";
  }
  
  /// رسالة خطأ عند عدم صحة الإعدادات
  static String getConfigErrorMessage() {
    if (!isConfigValid()) {
      return '''
🚨 إعدادات ZegoCloud غير صحيحة!

يرجى:
1. إنشاء حساب على https://console.zegocloud.com/
2. إنشاء مشروع جديد
3. الحصول على App ID و App Sign
4. تحديث الملف: lib/src/config/zego_config.dart

الإعدادات المطلوبة:
- appID: رقم التطبيق الخاص بك
- appSign: مفتاح التطبيق الخاص بك
      ''';
    }
    return '';
  }
}

/// إعدادات متقدمة للصوت
class ZegoAudioSettings {
  static const Map<String, dynamic> highQuality = {
    'bitrate': 128,
    'sampleRate': 48000,
    'channels': 2,
    'codecID': 'OPUS',
  };
  
  static const Map<String, dynamic> mediumQuality = {
    'bitrate': 64,
    'sampleRate': 44100,
    'channels': 1,
    'codecID': 'OPUS',
  };
  
  static const Map<String, dynamic> lowQuality = {
    'bitrate': 32,
    'sampleRate': 22050,
    'channels': 1,
    'codecID': 'OPUS',
  };
}

/// أنواع الأحداث في ZegoCloud
enum ZegoEventType {
  userJoined,
  userLeft,
  microphoneOn,
  microphoneOff,
  speakerOn,
  speakerOff,
  roomStateChanged,
  audioQualityChanged,
  networkQualityChanged,
  messageReceived,
}

/// حالات الغرفة
enum ZegoRoomState {
  disconnected,
  connecting,
  connected,
  reconnecting,
}

/// حالات المايك
enum ZegoMicState {
  off,
  on,
  muted,
  requesting,
}

