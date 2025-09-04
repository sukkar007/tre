# 📱 دليل بناء APK - HUS App v2.0.0

## 🎯 إعدادات البيئة المطلوبة

### ✅ متطلبات النظام (متوافقة مع بيئتك)
- **Flutter**: 3.32.8 ✅
- **Dart**: 3.8.1 ✅
- **Java**: 21 ✅
- **Android SDK**: 35 ✅
- **Gradle**: 8.5 ✅

## 🚀 خطوات بناء APK

### 1. تحضير المشروع
```bash
# الانتقال لمجلد المشروع
cd hus_project/frontend

# تثبيت التبعيات
flutter pub get

# فحص التوافق
flutter doctor -v
```

### 2. إعداد Firebase (مطلوب)
```bash
# استبدل الملف التالي بملف Firebase الحقيقي:
# android/app/google-services.json

# الحصول على الملف من:
# https://console.firebase.google.com/
# Project Settings > General > Your apps > Download google-services.json
```

### 3. إعداد ZegoCloud (مطلوب)
```dart
// تحديث الملف: lib/src/config/zego_config.dart
class ZegoConfig {
  static const int appID = YOUR_REAL_APP_ID; // من ZegoCloud Console
  static const String appSign = 'YOUR_REAL_APP_SIGN'; // من ZegoCloud Console
}
```

### 4. بناء APK
```bash
# تنظيف المشروع
flutter clean

# إعادة تثبيت التبعيات
flutter pub get

# بناء APK للإصدار التجريبي
flutter build apk --debug

# أو بناء APK للإصدار النهائي
flutter build apk --release
```

## 📁 ملفات APK المُنتجة

### مسارات الملفات
```
build/app/outputs/flutter-apk/
├── app-debug.apk          # الإصدار التجريبي (~70-90 MB)
├── app-release.apk        # الإصدار النهائي (~40-60 MB)
└── app-arm64-v8a-release.apk  # محسن لمعالجات ARM64
```

## 🔧 إعدادات البناء المُحدثة

### Android Configuration
```gradle
// android/app/build.gradle
android {
    compileSdk 35                    // متوافق مع SDK 35
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_21  // Java 21
        targetCompatibility JavaVersion.VERSION_21
    }
    
    kotlinOptions {
        jvmTarget = '21'             // Kotlin target Java 21
    }
    
    defaultConfig {
        applicationId "com.flamingolive.hus"
        minSdkVersion 21             // دعم واسع للأجهزة
        targetSdkVersion 35          // أحدث إصدار
        versionCode 1
        versionName "2.0.0"
    }
}
```

### Gradle Configuration
```properties
# android/gradle/wrapper/gradle-wrapper.properties
distributionUrl=https://services.gradle.org/distributions/gradle-8.5-all.zip
```

## 🛠️ حل المشاكل الشائعة

### 1. خطأ Java Version
```bash
# إذا ظهر خطأ Java version
# تأكد من استخدام Java 21
java -version

# تحديث متغير JAVA_HOME إذا لزم الأمر
export JAVA_HOME=/path/to/java21
```

### 2. خطأ Android SDK
```bash
# إذا لم يتم العثور على SDK
flutter config --android-sdk C:\xsrc\sdk

# أو تحديث متغير ANDROID_HOME
export ANDROID_HOME=C:\xsrc\sdk
```

### 3. خطأ Firebase
```
Error: google-services.json not found
```
**الحل**: تحديث ملف `android/app/google-services.json` بملف Firebase الحقيقي

### 4. خطأ ZegoCloud
```
Error: ZegoCloud initialization failed
```
**الحل**: تحديث `lib/src/config/zego_config.dart` بمفاتيح API الحقيقية

### 5. خطأ التبعيات
```bash
# إذا فشل pub get
flutter clean
flutter pub cache repair
flutter pub get
```

## 📱 اختبار APK

### تثبيت على الجهاز
```bash
# تثبيت APK على جهاز متصل
flutter install

# أو تثبيت يدوي
adb install build/app/outputs/flutter-apk/app-debug.apk
```

### اختبار الميزات
1. **تسجيل الدخول**: اختبر Google Sign-in
2. **الغرف الصوتية**: إنشاء والانضمام للغرف
3. **YouTube**: إضافة وتشغيل فيديوهات
4. **الملفات الصوتية**: رفع وتشغيل ملفات MP3
5. **قائمة الانتظار**: إدارة قائمة التشغيل

## 🎯 تحسين حجم APK

### تقليل حجم الملف
```bash
# بناء APK مُحسن
flutter build apk --release --shrink

# بناء APK منفصل للمعمارية
flutter build apk --release --split-per-abi
```

### ملفات APK منفصلة
```
build/app/outputs/flutter-apk/
├── app-armeabi-v7a-release.apk    # للأجهزة القديمة (32-bit)
├── app-arm64-v8a-release.apk      # للأجهزة الحديثة (64-bit)
└── app-x86_64-release.apk         # للمحاكيات
```

## 📊 معلومات APK المتوقعة

### الأحجام المتوقعة
- **Debug APK**: 70-90 MB
- **Release APK**: 40-60 MB
- **Split APK (ARM64)**: 25-35 MB

### الصلاحيات المطلوبة
- الإنترنت والشبكة
- الميكروفون والصوت
- قراءة وكتابة الملفات
- الكاميرا (للمستقبل)
- الإشعارات
- Bluetooth للسماعات

### الميزات المدعومة
- Android 5.0+ (API 21+)
- معالجات ARM و x86
- دعم 32-bit و 64-bit
- جميع أحجام الشاشات

## 🔐 الأمان والتوقيع

### للإصدار التجريبي
```bash
# يستخدم debug keystore تلقائياً
flutter build apk --debug
```

### للإصدار الإنتاجي
```bash
# إنشاء keystore للتوقيع
keytool -genkey -v -keystore hus-release-key.keystore -alias hus -keyalg RSA -keysize 2048 -validity 10000

# تحديث android/key.properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=hus
storeFile=../hus-release-key.keystore
```

## 📋 قائمة التحقق النهائية

### قبل البناء
- [ ] Flutter 3.32.8 مثبت
- [ ] Java 21 مُعد
- [ ] Android SDK 35 متوفر
- [ ] ملف Firebase محدث
- [ ] مفاتيح ZegoCloud محدثة

### بعد البناء
- [ ] APK تم إنشاؤه بنجاح
- [ ] حجم الملف معقول
- [ ] التطبيق يعمل على الجهاز
- [ ] جميع الميزات تعمل
- [ ] لا توجد أخطاء في التشغيل

## 🎉 النتيجة النهائية

بعد اتباع هذه الخطوات، ستحصل على:
- **APK جاهز للتثبيت** 📱
- **جميع الميزات تعمل** ✅
- **متوافق مع بيئتك** 🎯
- **محسن للأداء** ⚡

---

**ملاحظة مهمة**: تأكد من تحديث إعدادات Firebase و ZegoCloud قبل البناء النهائي!

