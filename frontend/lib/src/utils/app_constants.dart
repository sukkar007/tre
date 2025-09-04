class AppConstants {
  // معلومات التطبيق
  static const String appName = 'HUS';
  static const String appFullName = 'HUS - تطبيق الدردشة الصوتية';
  static const String appVersion = '1.0.0';
  static const String packageName = 'com.flamingolive.hus';
  
  // عناوين الخادم
  static const String baseUrl = 'http://10.0.2.2:3000/api';
  static const String splashEndpoint = '/splash/content';
  static const String authEndpoint = '/auth/login';
  static const String verifyEndpoint = '/auth/verify';
  
  // مفاتيح التخزين المحلي
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String deviceIdKey = 'device_id';
  static const String splashCacheKey = 'splash_cache';
  static const String settingsKey = 'app_settings';
  
  // إعدادات الشاشات
  static const Duration splashMinDuration = Duration(seconds: 2);
  static const Duration splashMaxDuration = Duration(seconds: 5);
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);
  
  // أحجام الشاشات
  static const double maxMobileWidth = 600;
  static const double maxTabletWidth = 1024;
  
  // الألوان
  static const int primaryColorValue = 0xFF6366f1;
  static const int secondaryColorValue = 0xFF8b5cf6;
  static const int accentColorValue = 0xFFf59e0b;
  static const int successColorValue = 0xFF10b981;
  static const int warningColorValue = 0xFFf59e0b;
  static const int errorColorValue = 0xFFef4444;
  static const int infoColorValue = 0xFF06b6d4;
  
  // أحجام الخطوط
  static const double fontSizeSmall = 12;
  static const double fontSizeMedium = 14;
  static const double fontSizeLarge = 16;
  static const double fontSizeXLarge = 18;
  static const double fontSizeXXLarge = 20;
  static const double fontSizeTitle = 24;
  static const double fontSizeHeading = 32;
  
  // المسافات
  static const double paddingSmall = 8;
  static const double paddingMedium = 16;
  static const double paddingLarge = 24;
  static const double paddingXLarge = 32;
  
  static const double marginSmall = 8;
  static const double marginMedium = 16;
  static const double marginLarge = 24;
  static const double marginXLarge = 32;
  
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 20;
  static const double radiusCircular = 50;
  
  // أحجام الأيقونات
  static const double iconSizeSmall = 16;
  static const double iconSizeMedium = 24;
  static const double iconSizeLarge = 32;
  static const double iconSizeXLarge = 48;
  static const double iconSizeXXLarge = 64;
  
  // إعدادات الشبكة
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration connectionTimeout = Duration(seconds: 15);
  static const int maxRetryAttempts = 3;
  
  // إعدادات الملفات
  static const int maxImageSizeMB = 5;
  static const int maxVideoSizeMB = 50;
  static const int maxAudioSizeMB = 10;
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png', 'gif'];
  static const List<String> supportedVideoFormats = ['mp4', 'mov', 'avi'];
  static const List<String> supportedAudioFormats = ['mp3', 'wav', 'aac', 'm4a'];
  
  // رسائل الخطأ
  static const String networkErrorMessage = 'تحقق من اتصالك بالإنترنت وحاول مرة أخرى';
  static const String serverErrorMessage = 'حدث خطأ في الخادم، يرجى المحاولة لاحقاً';
  static const String unknownErrorMessage = 'حدث خطأ غير متوقع';
  static const String authErrorMessage = 'فشل في تسجيل الدخول، يرجى المحاولة مرة أخرى';
  static const String permissionErrorMessage = 'يرجى منح الصلاحيات المطلوبة للمتابعة';
  
  // رسائل النجاح
  static const String loginSuccessMessage = 'تم تسجيل الدخول بنجاح';
  static const String logoutSuccessMessage = 'تم تسجيل الخروج بنجاح';
  static const String updateSuccessMessage = 'تم التحديث بنجاح';
  static const String saveSuccessMessage = 'تم الحفظ بنجاح';
  
  // إعدادات الغرف الصوتية
  static const int maxRoomParticipants = 50;
  static const int defaultRoomParticipants = 20;
  static const Duration roomIdleTimeout = Duration(minutes: 30);
  static const Duration micAutoMuteTimeout = Duration(seconds: 10);
  
  // إعدادات الرسائل
  static const int maxMessageLength = 500;
  static const int maxMessagesPerMinute = 10;
  static const Duration messageEditTimeout = Duration(minutes: 5);
  static const Duration messageDeleteTimeout = Duration(hours: 24);
  
  // إعدادات المنشورات
  static const int maxPostLength = 1000;
  static const int maxPostImagesCount = 5;
  static const Duration postEditTimeout = Duration(hours: 1);
  
  // إعدادات الملف الشخصي
  static const int maxBioLength = 200;
  static const int maxUsernameLength = 30;
  static const int minUsernameLength = 3;
  
  // أنماط التحقق
  static const String emailPattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^\+?[1-9]\d{1,14}$';
  static const String usernamePattern = r'^[a-zA-Z0-9_]{3,30}$';
  
  // روابط مهمة
  static const String privacyPolicyUrl = 'https://husapp.com/privacy';
  static const String termsOfServiceUrl = 'https://husapp.com/terms';
  static const String supportUrl = 'https://husapp.com/support';
  static const String feedbackUrl = 'https://husapp.com/feedback';
  
  // إعدادات الإشعارات
  static const String notificationChannelId = 'hus_notifications';
  static const String notificationChannelName = 'HUS Notifications';
  static const String notificationChannelDescription = 'إشعارات تطبيق HUS';
  
  // مفاتيح التحليلات
  static const String analyticsUserLogin = 'user_login';
  static const String analyticsUserLogout = 'user_logout';
  static const String analyticsRoomJoin = 'room_join';
  static const String analyticsRoomCreate = 'room_create';
  static const String analyticsMessageSend = 'message_send';
  static const String analyticsPostCreate = 'post_create';
  
  // إعدادات التخزين المؤقت
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCacheSize = 100; // عدد العناصر
  static const Duration imageCacheExpiration = Duration(days: 7);
  
  // إعدادات الأمان
  static const Duration tokenRefreshInterval = Duration(minutes: 55);
  static const Duration sessionTimeout = Duration(hours: 24);
  static const int maxLoginAttempts = 5;
  static const Duration loginCooldown = Duration(minutes: 15);
}

