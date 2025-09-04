# دليل دمج ZegoCloud في تطبيق HUS

## 📋 نظرة عامة

تم دمج ZegoCloud SDK بنجاح في تطبيق HUS لتوفير غرف صوتية حقيقية عالية الجودة. هذا الدليل يوضح كيفية إعداد واستخدام الميزات الصوتية.

## 🎯 الميزات المدمجة

### ✅ الميزات الأساسية
- **غرف صوتية حقيقية** مع دعم متعدد المستخدمين
- **تحكم كامل في المايك والسماعة**
- **مراقبة مستوى الصوت** في الوقت الفعلي
- **إدارة حالة الاتصال** مع إعادة الاتصال التلقائي
- **أدوار المستخدمين** (مالك، متحدث، مستمع)

### ✅ الميزات المتقدمة
- **إلغاء الصدى** (Echo Cancellation)
- **تقليل الضوضاء** (Noise Suppression)
- **التحكم التلقائي في الصوت** (Auto Gain Control)
- **جودة صوت قابلة للتخصيص** (منخفضة، متوسطة، عالية)
- **مؤشرات بصرية** للتحدث والكتم

## 🔧 إعداد ZegoCloud

### 1. الحصول على بيانات الاعتماد

```dart
// في ملف lib/src/config/zego_config.dart
class ZegoConfig {
  // احصل على هذه القيم من لوحة تحكم ZegoCloud
  static const int appID = YOUR_APP_ID;
  static const String appSign = 'YOUR_APP_SIGN';
  static const String serverSecret = 'YOUR_SERVER_SECRET';
}
```

### 2. تحديث pubspec.yaml

```yaml
dependencies:
  zego_uikit_prebuilt_live_audio_room: ^4.0.0
  zego_uikit: ^4.0.0
  permission_handler: ^11.0.0
```

### 3. إعدادات Android

في `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
```

### 4. إعدادات iOS

في `ios/Runner/Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>يحتاج التطبيق للوصول للمايك للمشاركة في الغرف الصوتية</string>
```

## 🎤 استخدام الغرف الصوتية

### إنشاء غرفة صوتية جديدة

```dart
// الانتقال إلى غرفة صوتية
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ZegoAudioRoomScreen(
      roomId: 'room_123',
      currentUser: currentUser,
      userRole: 'host', // أو 'speaker' أو 'audience'
    ),
  ),
);
```

### التحكم في الصوت

```dart
// تشغيل/إيقاف المايك
await zegoService.toggleMicrophone();

// تشغيل/إيقاف السماعة
await zegoService.toggleSpeaker();

// بدء البث الصوتي
await zegoService.startPublishing();

// إيقاف البث الصوتي
await zegoService.stopPublishing();
```

### مراقبة الأحداث

```dart
// مراقبة حالة الغرفة
zegoService.roomStateStream.listen((state) {
  switch (state) {
    case ZegoRoomState.connected:
      print('متصل بالغرفة');
      break;
    case ZegoRoomState.disconnected:
      print('منقطع عن الغرفة');
      break;
  }
});

// مراقبة المستخدمين
zegoService.usersStream.listen((users) {
  print('المستخدمون المتصلون: ${users.length}');
});

// مراقبة حالات المايكات
zegoService.micStatesStream.listen((micStates) {
  micStates.forEach((userId, isMuted) {
    print('المستخدم $userId: ${isMuted ? "مكتوم" : "يتحدث"}');
  });
});
```

## 🎛️ إعدادات الصوت المتقدمة

### تحسين جودة الصوت

```dart
// تفعيل إلغاء الصدى
await zegoService.updateAudioSettings(
  enableEchoCancellation: true,
);

// تفعيل تقليل الضوضاء
await zegoService.updateAudioSettings(
  enableNoiseSuppression: true,
);

// تفعيل التحكم التلقائي في الصوت
await zegoService.updateAudioSettings(
  enableAutoGainControl: true,
);

// تحديد جودة الصوت
await zegoService.updateAudioSettings(
  audioQuality: 'high', // 'low', 'medium', 'high'
);
```

### إدارة الأذونات

```dart
// طلب أذونات المايك
await zegoService.requestMicrophonePermission();

// التحقق من الأذونات
bool hasPermission = await zegoService.checkMicrophonePermission();
```

## 🔄 إدارة دورة الحياة

### تهيئة الخدمة

```dart
class _MyAppState extends State<MyApp> {
  final ZegoAudioService _zegoService = ZegoAudioService();

  @override
  void initState() {
    super.initState();
    _initializeZego();
  }

  Future<void> _initializeZego() async {
    final success = await _zegoService.initialize();
    if (!success) {
      // معالجة خطأ التهيئة
    }
  }

  @override
  void dispose() {
    _zegoService.dispose();
    super.dispose();
  }
}
```

### الانضمام إلى غرفة

```dart
Future<void> joinRoom(String roomId, UserModel user) async {
  try {
    final success = await _zegoService.joinRoom(
      roomID: roomId,
      user: user,
      userRole: 'audience',
    );
    
    if (success) {
      print('تم الانضمام بنجاح');
    }
  } catch (e) {
    print('خطأ في الانضمام: $e');
  }
}
```

### مغادرة الغرفة

```dart
Future<void> leaveRoom() async {
  try {
    await _zegoService.leaveRoom();
    print('تم مغادرة الغرفة');
  } catch (e) {
    print('خطأ في المغادرة: $e');
  }
}
```

## 🛠️ استكشاف الأخطاء

### مشاكل شائعة وحلولها

#### 1. فشل التهيئة
```dart
// التحقق من صحة الإعدادات
if (!ZegoConfig.isConfigValid()) {
  print('خطأ في إعدادات ZegoCloud: ${ZegoConfig.getConfigErrorMessage()}');
}
```

#### 2. مشاكل الأذونات
```dart
// طلب الأذونات مرة أخرى
await Permission.microphone.request();
```

#### 3. مشاكل الاتصال
```dart
// إعادة الاتصال
await _zegoService.reconnect();
```

#### 4. مشاكل الصوت
```dart
// إعادة تعيين إعدادات الصوت
await _zegoService.resetAudioSettings();
```

## 📊 مراقبة الأداء

### إحصائيات الشبكة

```dart
// مراقبة جودة الشبكة
zegoService.networkQualityStream.listen((quality) {
  switch (quality) {
    case ZegoNetworkQuality.excellent:
      print('جودة ممتازة');
      break;
    case ZegoNetworkQuality.good:
      print('جودة جيدة');
      break;
    case ZegoNetworkQuality.poor:
      print('جودة ضعيفة');
      break;
  }
});
```

### إحصائيات الصوت

```dart
// مراقبة مستوى الصوت
zegoService.audioLevelStream.listen((level) {
  print('مستوى الصوت: $level');
});
```

## 🔐 الأمان والخصوصية

### التحقق من الهوية

```dart
// إنشاء توكن آمن للمستخدم
String token = await _zegoService.generateUserToken(
  userId: user.id,
  roomId: roomId,
);
```

### تشفير البيانات

```dart
// تفعيل التشفير
await _zegoService.enableEncryption(true);
```

## 📱 اختبار التطبيق

### اختبار محلي

1. **تشغيل الواجهة الخلفية:**
   ```bash
   cd backend
   npm install
   node server.js
   ```

2. **تشغيل تطبيق Flutter:**
   ```bash
   cd frontend
   flutter pub get
   flutter run
   ```

3. **اختبار الغرف الصوتية:**
   - إنشاء غرفة جديدة
   - الانضمام من أجهزة متعددة
   - اختبار التحكم في المايك والسماعة

### اختبار الإنتاج

1. **اختبار على أجهزة حقيقية**
2. **اختبار شبكات مختلفة**
3. **اختبار حالات الانقطاع**
4. **اختبار الأداء مع عدد كبير من المستخدمين**

## 🚀 النشر

### متطلبات النشر

1. **حساب ZegoCloud مدفوع** للإنتاج
2. **شهادات SSL** للواجهة الخلفية
3. **إعدادات Firebase** للإشعارات
4. **اختبار شامل** على أجهزة متعددة

### خطوات النشر

1. **تحديث إعدادات الإنتاج:**
   ```dart
   // في zego_config.dart
   static const bool isProduction = true;
   static const String productionServerUrl = 'https://your-server.com';
   ```

2. **بناء التطبيق:**
   ```bash
   flutter build apk --release
   flutter build ios --release
   ```

3. **رفع للمتاجر:**
   - Google Play Store
   - Apple App Store

## 📞 الدعم والمساعدة

### موارد مفيدة

- **وثائق ZegoCloud:** [https://docs.zegocloud.com](https://docs.zegocloud.com)
- **مجتمع المطورين:** [https://discord.gg/zegocloud](https://discord.gg/zegocloud)
- **دعم فني:** support@zegocloud.com

### تواصل معنا

إذا واجهت أي مشاكل أو لديك أسئلة، يمكنك:

1. **فتح issue** في مستودع GitHub
2. **مراجعة الوثائق** المفصلة
3. **التواصل مع فريق الدعم**

---

## 🎉 خلاصة

تم دمج ZegoCloud بنجاح في تطبيق HUS مع جميع الميزات المطلوبة:

- ✅ **غرف صوتية حقيقية** عالية الجودة
- ✅ **تحكم متقدم** في الصوت والمايك
- ✅ **واجهة مستخدم** بديهية وجميلة
- ✅ **إدارة شاملة** للمستخدمين والصلاحيات
- ✅ **مراقبة الأداء** والإحصائيات
- ✅ **أمان وخصوصية** عالية

التطبيق الآن جاهز للاختبار والنشر! 🚀

