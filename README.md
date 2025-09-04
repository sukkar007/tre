# HUS - تطبيق الدردشة الصوتية

![HUS Logo](https://via.placeholder.com/200x100/6366f1/ffffff?text=HUS)

## 📱 نظرة عامة

**HUS** هو تطبيق دردشة صوتية متطور مبني باستخدام Flutter للواجهة الأمامية و Node.js للواجهة الخلفية. يوفر التطبيق تجربة دردشة صوتية تفاعلية مع ميزات متقدمة مثل إدارة الغرف، والتحكم في الصوت، ومشاركة المحتوى.

## ✨ الميزات الرئيسية

### 🎤 الغرف الصوتية
- إنشاء وإدارة غرف الدردشة الصوتية
- التحكم في المايكات والصوت
- نظام صلاحيات متقدم (مالك، مدير، مستخدم)
- فلترة الكلمات السيئة
- دعم مشاهدة فيديوهات YouTube جماعياً
- تشغيل الموسيقى من ملفات الجوال

### 🔐 نظام المصادقة
- تسجيل الدخول عبر Google
- تسجيل الدخول عبر رقم الهاتف (Firebase)
- حفظ آمن للتوكنات
- إدارة جلسات المستخدمين

### 📱 الواجهات
- تصميم عصري ومتجاوب
- شاشة Splash ديناميكية من الخادم
- نظام إعلانات مدمج
- واجهة مستخدم سهلة وبديهية

### 🛡️ الأمان والخصوصية
- تشفير البيانات الحساسة
- فلترة المحتوى غير المناسب
- نظام حظر المستخدمين
- تتبع الأجهزة لمنع التلاعب

## 🏗️ البنية التقنية

### Frontend (Flutter)
- **Framework:** Flutter 3.x
- **Language:** Dart
- **State Management:** Provider
- **Authentication:** Firebase Auth
- **Storage:** Flutter Secure Storage
- **Audio:** ZegoCloud SDK

### Backend (Node.js)
- **Framework:** Fastify
- **Database:** MongoDB Atlas
- **Authentication:** JWT + Firebase Admin
- **Logging:** Pino
- **Validation:** Joi

## 📋 متطلبات النظام

### للتطوير
- **Flutter SDK:** 3.0.0 أو أحدث
- **Dart SDK:** 3.0.0 أو أحدث
- **Node.js:** 18.0.0 أو أحدث
- **npm:** 8.0.0 أو أحدث
- **Java JDK:** 21
- **Android SDK:** 35

### للإنتاج
- **MongoDB Atlas:** حساب مجاني أو مدفوع
- **Firebase Project:** مع تفعيل Authentication
- **ZegoCloud Account:** للميزات الصوتية

## 🚀 دليل التثبيت والتشغيل

### 1. استنساخ المشروع
```bash
git clone https://github.com/sukkar007/tre.git
cd tre
```

### 2. إعداد الواجهة الخلفية (Backend)

#### تثبيت التبعيات
```bash
cd backend
npm install
```

#### إعداد متغيرات البيئة
```bash
cp .env.example .env
```

قم بتحرير ملف `.env` وإضافة:
```env
# MongoDB Connection String
MONGO_URI=mongodb+srv://username:password@cluster.mongodb.net/database_name

# JWT Secret Key
JWT_SECRET=your_very_strong_and_secret_jwt_key_here

# Node Environment
NODE_ENV=development

# Server Configuration
PORT=3000
HOST=0.0.0.0
```

#### تشغيل الخادم
```bash
node server.js
```

### 3. إعداد تطبيق Flutter

#### تثبيت التبعيات
```bash
cd ../frontend
flutter pub get
```

#### إعداد Firebase
1. إنشاء مشروع Firebase جديد
2. تفعيل Authentication (Google + Phone)
3. تحميل ملف `google-services.json` ووضعه في `android/app/`
4. تحديث ملف `firebase_options.dart`

#### تشغيل التطبيق
```bash
flutter run
```

## 🧪 اختبار المشروع

### اختبار الواجهة الخلفية
```bash
cd backend
node test_api.js
```

### اختبار تطبيق Flutter
```bash
cd frontend
flutter test
```

## 📁 هيكل المشروع

```
hus_project/
├── backend/                 # الواجهة الخلفية (Node.js)
│   ├── models/             # نماذج قاعدة البيانات
│   ├── routes/             # مسارات API
│   ├── middleware/         # وسطاء المعالجة
│   ├── utils/              # أدوات مساعدة
│   ├── server.js           # ملف الخادم الرئيسي
│   ├── package.json        # تبعيات Node.js
│   └── .env                # متغيرات البيئة
├── frontend/               # تطبيق Flutter
│   ├── lib/
│   │   ├── src/
│   │   │   ├── models/     # نماذج البيانات
│   │   │   ├── screens/    # شاشات التطبيق
│   │   │   ├── services/   # خدمات API
│   │   │   ├── utils/      # أدوات مساعدة
│   │   │   └── widgets/    # مكونات UI
│   │   └── main.dart       # نقطة دخول التطبيق
│   ├── android/            # إعدادات Android
│   ├── ios/                # إعدادات iOS
│   └── pubspec.yaml        # تبعيات Flutter
└── README.md               # هذا الملف
```

## 🔧 إعدادات التطوير

### متغيرات البيئة المطلوبة

#### Backend (.env)
```env
MONGO_URI=mongodb+srv://...
JWT_SECRET=your_secret_key
NODE_ENV=development
PORT=3000
HOST=0.0.0.0
```

#### Flutter (firebase_options.dart)
```dart
static const FirebaseOptions android = FirebaseOptions(
  apiKey: 'your-api-key',
  appId: 'your-app-id',
  messagingSenderId: 'your-sender-id',
  projectId: 'your-project-id',
  storageBucket: 'your-storage-bucket',
);
```

## 📱 الشاشات المتاحة

### 1. شاشة Splash
- محتوى ديناميكي من الخادم
- نظام إعلانات مدمج
- رسوم متحركة قابلة للتخصيص

### 2. شاشة تسجيل الدخول
- تسجيل دخول Google
- تسجيل دخول برقم الهاتف
- تصميم عصري ومتجاوب

### 3. الشاشة الرئيسية
- التنقل بين الأقسام الأربعة
- Bottom Navigation متحرك
- FloatingActionButton لإنشاء غرف

### 4. شاشة الملف الشخصي
- معلومات المستخدم
- إحصائيات الاستخدام
- إعدادات الحساب

### 5. شاشة المنشورات
- عرض منشورات المجتمع
- إنشاء منشورات جديدة
- تفاعلات (إعجاب، تعليق، مشاركة)

### 6. شاشة الرسائل
- قائمة المحادثات
- مؤشرات الحالة
- بحث في الرسائل

### 7. شاشة الغرف الصوتية
- قائمة الغرف المتاحة
- فلاتر الفئات
- انضمام للغرف

## 🔌 API Endpoints

### Authentication
- `POST /api/auth/login` - تسجيل الدخول
- `POST /api/auth/verify` - التحقق من التوكن
- `POST /api/auth/logout` - تسجيل الخروج

### Splash Content
- `GET /api/splash/content` - الحصول على محتوى Splash
- `POST /api/splash/content` - إنشاء محتوى جديد
- `POST /api/splash/ad-click` - تسجيل نقرة إعلان

### Users
- `GET /api/users/profile` - الحصول على الملف الشخصي
- `PUT /api/users/profile` - تحديث الملف الشخصي
- `DELETE /api/users/account` - حذف الحساب

## 🛠️ أدوات التطوير

### Scripts مفيدة

#### Backend
```bash
# تشغيل الخادم في وضع التطوير
npm run dev

# تشغيل الاختبارات
npm test

# فحص الكود
npm run lint
```

#### Frontend
```bash
# تشغيل التطبيق
flutter run

# بناء APK
flutter build apk

# تشغيل الاختبارات
flutter test

# تحليل الكود
flutter analyze
```

## 🐛 استكشاف الأخطاء

### مشاكل شائعة وحلولها

#### 1. خطأ اتصال قاعدة البيانات
```
Error: MongoNetworkError
```
**الحل:** تحقق من رابط MongoDB في ملف `.env`

#### 2. خطأ Firebase
```
Error: Firebase project not found
```
**الحل:** تحقق من إعدادات Firebase في `firebase_options.dart`

#### 3. خطأ تبعيات Flutter
```
Error: Package not found
```
**الحل:** تشغيل `flutter pub get`

#### 4. خطأ Android SDK
```
Error: Android SDK not found
```
**الحل:** تحديث متغير `ANDROID_HOME`

## 📈 خطط التطوير المستقبلية

### المرحلة القادمة
- [ ] دمج ZegoCloud للغرف الصوتية
- [ ] نظام الرسائل الفورية
- [ ] إدارة المنشورات والتعليقات
- [ ] نظام الإشعارات

### ميزات متقدمة
- [ ] البث المباشر
- [ ] الألعاب التفاعلية
- [ ] نظام النقاط والمكافآت
- [ ] التكامل مع منصات التواصل

## 🤝 المساهمة

نرحب بمساهماتكم! يرجى اتباع الخطوات التالية:

1. Fork المشروع
2. إنشاء فرع جديد (`git checkout -b feature/amazing-feature`)
3. Commit التغييرات (`git commit -m 'Add amazing feature'`)
4. Push للفرع (`git push origin feature/amazing-feature`)
5. فتح Pull Request

## 📄 الترخيص

هذا المشروع مرخص تحت رخصة MIT. راجع ملف `LICENSE` للتفاصيل.

## 📞 التواصل والدعم

- **البريد الإلكتروني:** flamingolive007@gmail.com
- **GitHub Issues:** [رابط المشاكل](https://github.com/sukkar007/tre/issues)

## 🙏 شكر وتقدير

شكر خاص لجميع المطورين والمساهمين في هذا المشروع:
- فريق Flutter لإطار العمل الرائع
- فريق Firebase للخدمات السحابية
- مجتمع MongoDB للدعم المستمر
- ZegoCloud لحلول الصوت والفيديو

---

**تم تطوير هذا المشروع بـ ❤️ من قبل فريق HUS**

*آخر تحديث: سبتمبر 2025*

