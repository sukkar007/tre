# HUS App - تطبيق الدردشة الصوتية

تطبيق اجتماعي للدردشة الصوتية مبني باستخدام Flutter و Node.js مع دمج ZegoCloud للغرف الصوتية.

## 🚀 الميزات

### ✅ المنجز حالياً:
- **المصادقة (Authentication):**
  - تسجيل الدخول باستخدام Google
  - تسجيل الدخول برقم الهاتف (Firebase)
  - نظام توكن JWT مخصص
  - تتبع معرّفات الأجهزة لأغراض الأمان

- **الواجهة الخلفية (Backend):**
  - خادم Node.js باستخدام Fastify
  - قاعدة بيانات MongoDB
  - نظام إدارة المستخدمين
  - API آمن للمصادقة

### 🔄 قيد التطوير:
- **غرف الدردشة الصوتية:**
  - إنشاء وإدارة الغرف
  - نظام الصلاحيات (مالك، مسؤولين، محظورين)
  - التحكم في الميكروفونات والمقاعد
  - فلترة الكلمات السيئة

- **ميزات متقدمة:**
  - مشاهدة YouTube مشتركة
  - تشغيل الموسيقى من الجهاز
  - نظام الرسائل داخل الغرف

## 🏗️ البنية التقنية

### Frontend (Flutter)
- **اللغة:** Dart
- **إطار العمل:** Flutter
- **المصادقة:** Firebase Auth
- **الدردشة الصوتية:** ZegoCloud SDK
- **متطلبات النظام:** Android SDK 35, JDK 21

### Backend (Node.js)
- **اللغة:** JavaScript (Node.js)
- **إطار العمل:** Fastify
- **قاعدة البيانات:** MongoDB
- **المصادقة:** Firebase Admin SDK + JWT
- **التخزين المؤقت:** Redis (مخطط)

## 📁 هيكل المشروع

```
hus_project/
├── frontend/           # تطبيق Flutter
│   ├── lib/
│   │   ├── src/
│   │   │   ├── screens/    # شاشات التطبيق
│   │   │   └── services/   # خدمات API والمصادقة
│   │   └── main.dart
│   ├── android/
│   └── pubspec.yaml
├── backend/            # خادم Node.js
│   ├── models/         # نماذج قاعدة البيانات
│   ├── routes/         # مسارات API
│   ├── server.js       # الملف الرئيسي
│   └── package.json
└── README.md
```

## 🛠️ التثبيت والتشغيل

### متطلبات النظام:
- Node.js (v16+)
- Flutter SDK
- MongoDB Atlas أو MongoDB محلي
- Firebase Project
- ZegoCloud Account

### الواجهة الخلفية (Backend):
```bash
cd backend
npm install
# إنشاء ملف .env وإضافة:
# MONGO_URI=your_mongodb_connection_string
# JWT_SECRET=your_jwt_secret
# إضافة ملف serviceAccountKey.json من Firebase
node server.js
```

### تطبيق Flutter:
```bash
cd frontend/hus_app
flutter pub get
# تكوين Firebase باستخدام FlutterFire CLI
flutterfire configure
flutter run
```

## 🔐 الأمان

- جميع كلمات المرور وملفات المفاتيح محمية بـ .gitignore
- نظام JWT للتوكنات الآمنة
- تتبع معرّفات الأجهزة لمنع التلاعب
- فلترة المحتوى والكلمات السيئة

## 📝 المساهمة

هذا مشروع خاص قيد التطوير. للمساهمة أو الاستفسارات، يرجى التواصل مع فريق التطوير.

## 📄 الترخيص

جميع الحقوق محفوظة © 2025 Flamingo Live

---

**آخر تحديث:** ${new Date().toLocaleDateString('ar-SA')}
**الحالة:** قيد التطوير النشط 🚧

