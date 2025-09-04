# دليل النشر والتوزيع - HUS App

## 🚀 نظرة عامة

هذا الدليل يوضح كيفية نشر تطبيق HUS في بيئات مختلفة، من التطوير المحلي إلى الإنتاج.

## 📋 قائمة المراجعة قبل النشر

### ✅ الواجهة الخلفية (Backend)
- [ ] تحديث متغيرات البيئة للإنتاج
- [ ] تأمين مفاتيح JWT
- [ ] تكوين قاعدة البيانات للإنتاج
- [ ] تفعيل HTTPS
- [ ] إعداد نظام المراقبة
- [ ] تكوين النسخ الاحتياطية

### ✅ تطبيق Flutter
- [ ] تحديث إعدادات Firebase للإنتاج
- [ ] تحديث عناوين API
- [ ] إنشاء مفاتيح التوقيع
- [ ] اختبار التطبيق على أجهزة مختلفة
- [ ] تحسين الأداء والحجم
- [ ] إعداد متجر التطبيقات

## 🖥️ نشر الواجهة الخلفية

### 1. النشر على خادم VPS

#### متطلبات الخادم
```bash
# الحد الأدنى للمواصفات
- CPU: 2 cores
- RAM: 4GB
- Storage: 20GB SSD
- OS: Ubuntu 20.04 LTS أو أحدث
```

#### خطوات التثبيت
```bash
# 1. تحديث النظام
sudo apt update && sudo apt upgrade -y

# 2. تثبيت Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# 3. تثبيت PM2 لإدارة العمليات
sudo npm install -g pm2

# 4. تثبيت Nginx
sudo apt install nginx -y

# 5. تثبيت SSL (Let's Encrypt)
sudo apt install certbot python3-certbot-nginx -y
```

#### تكوين التطبيق
```bash
# 1. استنساخ المشروع
git clone https://github.com/sukkar007/tre.git
cd tre/backend

# 2. تثبيت التبعيات
npm install --production

# 3. إنشاء ملف البيئة للإنتاج
cp .env.example .env.production
```

#### ملف .env.production
```env
# MongoDB Connection (Production)
MONGO_URI=mongodb+srv://prod_user:secure_password@cluster.mongodb.net/hus_production

# JWT Secret (Generate strong key)
JWT_SECRET=super_secure_production_jwt_key_2024_hus_app

# Node Environment
NODE_ENV=production

# Server Configuration
PORT=3000
HOST=0.0.0.0

# Security Headers
CORS_ORIGIN=https://yourdomain.com
RATE_LIMIT_MAX=100
RATE_LIMIT_WINDOW=900000

# Logging
LOG_LEVEL=info
LOG_FILE=/var/log/hus/app.log
```

#### تكوين PM2
```bash
# إنشاء ملف ecosystem.config.js
cat > ecosystem.config.js << EOF
module.exports = {
  apps: [{
    name: 'hus-backend',
    script: 'server.js',
    env_production: {
      NODE_ENV: 'production',
      PORT: 3000
    },
    instances: 'max',
    exec_mode: 'cluster',
    max_memory_restart: '1G',
    error_file: '/var/log/hus/error.log',
    out_file: '/var/log/hus/out.log',
    log_file: '/var/log/hus/combined.log',
    time: true
  }]
};
EOF

# تشغيل التطبيق
pm2 start ecosystem.config.js --env production
pm2 save
pm2 startup
```

#### تكوين Nginx
```nginx
# /etc/nginx/sites-available/hus-backend
server {
    listen 80;
    server_name api.yourdomain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
```

```bash
# تفعيل الموقع
sudo ln -s /etc/nginx/sites-available/hus-backend /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx

# إعداد SSL
sudo certbot --nginx -d api.yourdomain.com
```

### 2. النشر على Docker

#### Dockerfile للواجهة الخلفية
```dockerfile
# backend/Dockerfile
FROM node:18-alpine

WORKDIR /app

# نسخ ملفات package
COPY package*.json ./

# تثبيت التبعيات
RUN npm ci --only=production

# نسخ الكود
COPY . .

# إنشاء مستخدم غير root
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

# تغيير الملكية
RUN chown -R nodejs:nodejs /app
USER nodejs

# تعريض المنفذ
EXPOSE 3000

# تشغيل التطبيق
CMD ["node", "server.js"]
```

#### docker-compose.yml
```yaml
version: '3.8'

services:
  backend:
    build: ./backend
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - MONGO_URI=${MONGO_URI}
      - JWT_SECRET=${JWT_SECRET}
    restart: unless-stopped
    volumes:
      - ./logs:/app/logs
    depends_on:
      - mongodb

  mongodb:
    image: mongo:6.0
    ports:
      - "27017:27017"
    environment:
      - MONGO_INITDB_ROOT_USERNAME=${MONGO_ROOT_USER}
      - MONGO_INITDB_ROOT_PASSWORD=${MONGO_ROOT_PASSWORD}
    volumes:
      - mongodb_data:/data/db
    restart: unless-stopped

  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - backend
    restart: unless-stopped

volumes:
  mongodb_data:
```

## 📱 نشر تطبيق Flutter

### 1. إعداد التطبيق للإنتاج

#### تحديث إعدادات Firebase
```dart
// lib/firebase_options.dart
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'your-production-api-key',
    appId: 'your-production-app-id',
    messagingSenderId: 'your-sender-id',
    projectId: 'your-production-project-id',
    storageBucket: 'your-production-storage-bucket',
  );
}
```

#### تحديث عناوين API
```dart
// lib/src/utils/app_constants.dart
class AppConstants {
  static const String baseUrl = kDebugMode 
    ? 'http://10.0.2.2:3000/api'  // للتطوير
    : 'https://api.yourdomain.com/api';  // للإنتاج
}
```

### 2. بناء APK للإنتاج

#### إعداد مفاتيح التوقيع
```bash
# إنشاء keystore
keytool -genkey -v -keystore ~/hus-release-key.keystore -keyalg RSA -keysize 2048 -validity 10000 -alias hus-key
```

#### تكوين android/key.properties
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=hus-key
storeFile=/path/to/hus-release-key.keystore
```

#### تحديث android/app/build.gradle
```gradle
android {
    ...
    signingConfigs {
        release {
            keyAlias keystoreProperties['keyAlias']
            keyPassword keystoreProperties['keyPassword']
            storeFile keystoreProperties['storeFile'] ? file(keystoreProperties['storeFile']) : null
            storePassword keystoreProperties['storePassword']
        }
    }
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            shrinkResources true
        }
    }
}
```

#### بناء APK
```bash
# تنظيف المشروع
flutter clean
flutter pub get

# بناء APK للإنتاج
flutter build apk --release

# بناء App Bundle (للـ Play Store)
flutter build appbundle --release
```

### 3. نشر على متجر Google Play

#### متطلبات المتجر
- [ ] حساب Google Play Developer ($25)
- [ ] أيقونة التطبيق (512x512)
- [ ] لقطات شاشة (مختلف الأحجام)
- [ ] وصف التطبيق
- [ ] سياسة الخصوصية
- [ ] شروط الاستخدام

#### خطوات النشر
1. **إنشاء التطبيق في Play Console**
2. **رفع App Bundle**
3. **إضافة معلومات المتجر**
4. **تكوين التسعير والتوزيع**
5. **مراجعة وإرسال للمراجعة**

## 🔒 الأمان في الإنتاج

### إعدادات الأمان للخادم
```bash
# تكوين جدار الحماية
sudo ufw enable
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443

# تأمين SSH
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# تثبيت Fail2Ban
sudo apt install fail2ban -y
```

### متغيرات البيئة الآمنة
```bash
# استخدام أدوات إدارة الأسرار
# مثل HashiCorp Vault أو AWS Secrets Manager

# أو على الأقل تشفير ملف .env
gpg --symmetric --cipher-algo AES256 .env
```

## 📊 المراقبة والتحليلات

### إعداد المراقبة
```javascript
// إضافة إلى server.js
const prometheus = require('prom-client');

// إنشاء metrics
const httpRequestDuration = new prometheus.Histogram({
  name: 'http_request_duration_seconds',
  help: 'Duration of HTTP requests in seconds',
  labelNames: ['method', 'route', 'status_code']
});

// middleware للمراقبة
app.addHook('onRequest', async (request, reply) => {
  request.startTime = Date.now();
});

app.addHook('onResponse', async (request, reply) => {
  const duration = (Date.now() - request.startTime) / 1000;
  httpRequestDuration
    .labels(request.method, request.url, reply.statusCode)
    .observe(duration);
});
```

### إعداد التحليلات
```dart
// في Flutter
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  static Future<void> logEvent(String name, Map<String, dynamic> parameters) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }
  
  static Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
  }
}
```

## 🔄 التحديثات والصيانة

### استراتيجية التحديث
```bash
# إنشاء script للتحديث
cat > update.sh << 'EOF'
#!/bin/bash

echo "🔄 بدء عملية التحديث..."

# إيقاف التطبيق
pm2 stop hus-backend

# سحب آخر التحديثات
git pull origin main

# تثبيت التبعيات الجديدة
npm install --production

# تشغيل migrations إذا لزم الأمر
# npm run migrate

# إعادة تشغيل التطبيق
pm2 start hus-backend

echo "✅ تم التحديث بنجاح!"
EOF

chmod +x update.sh
```

### النسخ الاحتياطية
```bash
# script للنسخ الاحتياطي
cat > backup.sh << 'EOF'
#!/bin/bash

DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="/backups/hus_$DATE"

# إنشاء مجلد النسخ الاحتياطي
mkdir -p $BACKUP_DIR

# نسخ احتياطي لقاعدة البيانات
mongodump --uri="$MONGO_URI" --out="$BACKUP_DIR/database"

# نسخ احتياطي للملفات
tar -czf "$BACKUP_DIR/files.tar.gz" /path/to/app/files

# رفع للتخزين السحابي (اختياري)
# aws s3 cp $BACKUP_DIR s3://your-backup-bucket/ --recursive

echo "✅ تم إنشاء النسخة الاحتياطية: $BACKUP_DIR"
EOF

chmod +x backup.sh

# إضافة إلى crontab للتشغيل التلقائي
echo "0 2 * * * /path/to/backup.sh" | crontab -
```

## 📈 تحسين الأداء

### تحسين قاعدة البيانات
```javascript
// إضافة فهارس مهمة
db.users.createIndex({ "email": 1 }, { unique: true });
db.users.createIndex({ "firebaseUid": 1 }, { unique: true });
db.users.createIndex({ "deviceId": 1 });
db.splashContents.createIndex({ "contentId": 1 }, { unique: true });
db.splashContents.createIndex({ "isActive": 1, "createdAt": -1 });
```

### تحسين Flutter
```dart
// تحسين حجم التطبيق
flutter build apk --release --split-per-abi

// تفعيل obfuscation
flutter build apk --release --obfuscate --split-debug-info=debug-info/
```

## 🚨 استكشاف الأخطاء

### مشاكل شائعة في الإنتاج

#### 1. مشكلة الذاكرة
```bash
# مراقبة استخدام الذاكرة
pm2 monit

# إعادة تشغيل عند تجاوز حد الذاكرة
pm2 start server.js --max-memory-restart 1G
```

#### 2. مشكلة قاعدة البيانات
```bash
# فحص حالة الاتصال
mongosh "mongodb+srv://cluster.mongodb.net/" --eval "db.runCommand('ping')"

# مراقبة الأداء
mongosh "mongodb+srv://cluster.mongodb.net/" --eval "db.runCommand({serverStatus: 1})"
```

#### 3. مشكلة SSL
```bash
# تجديد شهادة SSL
sudo certbot renew --dry-run

# فحص انتهاء الصلاحية
sudo certbot certificates
```

---

**ملاحظة:** هذا الدليل يغطي الأساسيات. للبيئات المعقدة، يُنصح بالتشاور مع خبير DevOps.

