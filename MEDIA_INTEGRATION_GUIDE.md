# دليل تكامل الوسائط - HUS App

## نظرة عامة

تم تطوير نظام وسائط متقدم لتطبيق HUS يدعم تشغيل فيديوهات YouTube والملفات الصوتية المحلية مع مزامنة في الوقت الفعلي بين جميع المستخدمين في الغرفة الصوتية.

## الميزات الرئيسية

### 1. تشغيل فيديوهات YouTube
- **إضافة فيديوهات**: إضافة فيديوهات YouTube عبر الرابط
- **تشغيل متزامن**: مزامنة التشغيل بين جميع المستخدمين
- **أدوات التحكم**: تشغيل، إيقاف، تقديم، ترجيع
- **ملء الشاشة**: دعم وضع ملء الشاشة
- **معلومات الفيديو**: عرض عنوان الفيديو واسم القناة

### 2. تشغيل الملفات الصوتية
- **رفع الملفات**: رفع ملفات صوتية محلية (MP3, WAV, AAC, FLAC)
- **مشغل متقدم**: واجهة مشغل موسيقى احترافية
- **مصور صوتي**: عرض الموجات الصوتية المتحركة
- **قائمة تشغيل**: إدارة قائمة تشغيل الغرفة
- **تحكم متقدم**: سرعة التشغيل، مستوى الصوت، التكرار

### 3. إدارة قائمة الانتظار
- **قائمة ذكية**: ترتيب تلقائي حسب الشعبية
- **خلط وتكرار**: أوضاع خلط وتكرار متقدمة
- **تاريخ التشغيل**: حفظ تاريخ المحتوى المشغل
- **إحصائيات**: تتبع عدد مرات التشغيل والتقييمات

## البنية التقنية

### Frontend (Flutter)

#### الخدمات الأساسية

1. **MediaService** (`lib/src/services/media_service.dart`)
   - إدارة تشغيل الوسائط
   - مزامنة مع الخادم
   - تحكم في YouTube و AudioPlayer

2. **MediaQueueService** (`lib/src/services/media_queue_service.dart`)
   - إدارة قائمة الانتظار
   - أوضاع التشغيل (خلط، تكرار)
   - إحصائيات وتاريخ التشغيل

#### الواجهات (Widgets)

1. **YouTubePlayerWidget** (`lib/src/widgets/youtube_player_widget.dart`)
   - مشغل YouTube مع أدوات تحكم مخصصة
   - دعم ملء الشاشة
   - مزامنة في الوقت الفعلي

2. **AudioPlayerWidget** (`lib/src/widgets/audio_player_widget.dart`)
   - مشغل صوتي متقدم
   - مصور صوتي متحرك
   - واجهة مشغل موسيقى احترافية

3. **MediaControlPanel** (`lib/src/widgets/media_control_panel.dart`)
   - لوحة تحكم شاملة
   - إضافة محتوى جديد
   - إدارة قائمة التشغيل

#### النماذج (Models)

1. **MediaContent** (`lib/src/models/media_content_model.dart`)
   - نموذج المحتوى الموحد
   - دعم أنواع مختلفة من الوسائط
   - بيانات وصفية وإحصائيات

### Backend (Node.js + Fastify)

#### المسارات (Routes)

1. **Media Routes** (`backend/routes/media.js`)
   ```
   GET    /api/media/room/:roomId/active          # المحتوى النشط
   GET    /api/media/room/:roomId/content         # قائمة المحتوى
   POST   /api/media/room/:roomId/youtube         # إضافة YouTube
   POST   /api/media/room/:roomId/audio           # إضافة ملف صوتي
   POST   /api/media/room/:roomId/play            # بدء التشغيل
   POST   /api/media/room/:roomId/pause           # إيقاف مؤقت
   POST   /api/media/room/:roomId/stop            # إيقاف نهائي
   POST   /api/media/room/:roomId/seek            # تغيير الموقع
   POST   /api/media/room/:roomId/volume          # تغيير الصوت
   DELETE /api/media/room/:roomId/content/:id     # حذف محتوى
   ```

2. **Upload Routes** (`backend/routes/upload.js`)
   ```
   POST   /api/upload/audio                       # رفع ملف صوتي
   POST   /api/upload/audio/multiple              # رفع ملفات متعددة
   DELETE /api/upload/audio/:filename             # حذف ملف
   GET    /api/upload/audio/:filename/info        # معلومات الملف
   ```

#### الخدمات (Services)

1. **MediaService** (`backend/services/mediaService.js`)
   - إدارة تشغيل المحتوى
   - مزامنة الحالة
   - Socket.IO للتحديثات الفورية

2. **Socket Events**
   ```javascript
   // أحداث الوسائط
   media_started       // بدء التشغيل
   media_paused        // إيقاف مؤقت
   media_stopped       // إيقاف نهائي
   media_seeked        // تغيير الموقع
   media_volume_changed // تغيير الصوت
   media_sync          // مزامنة الحالة
   media_added         // إضافة محتوى
   media_deleted       // حذف محتوى
   ```

## التثبيت والإعداد

### 1. تثبيت التبعيات

#### Frontend
```bash
cd frontend
flutter pub get
```

#### Backend
```bash
cd backend
npm install
```

### 2. إعداد المتغيرات البيئية

#### Backend (.env)
```env
MONGO_URI=mongodb://localhost:27017/hus_app
BASE_URL=http://localhost:3000
FIREBASE_PROJECT_ID=your-project-id
```

### 3. تشغيل الخدمات

#### Backend
```bash
cd backend
npm run dev
```

#### Frontend
```bash
cd frontend
flutter run
```

## استخدام النظام

### 1. إضافة فيديو YouTube

```dart
final mediaService = MediaService();
await mediaService.addYouTubeVideo('https://www.youtube.com/watch?v=VIDEO_ID');
```

### 2. إضافة ملف صوتي

```dart
final mediaService = MediaService();
await mediaService.addAudioFile(); // يفتح منتقي الملفات
```

### 3. التحكم في التشغيل

```dart
// بدء التشغيل
await mediaService.startContent(contentId);

// إيقاف مؤقت
await mediaService.pauseContent();

// تغيير الموقع
await mediaService.seekTo(position);

// تغيير الصوت
await mediaService.changeVolume(volume);
```

### 4. إدارة قائمة الانتظار

```dart
final queueService = MediaQueueService();

// إضافة للقائمة
queueService.addToQueue(content);

// تشغيل التالي
await queueService.playNext();

// تبديل الخلط
queueService.toggleShuffle();

// تغيير وضع التكرار
queueService.toggleRepeatMode();
```

## الواجهات المحدثة

### 1. شاشة الغرفة الصوتية المحسنة

استخدم `EnhancedAudioRoomScreen` بدلاً من `AudioRoomScreen` للحصول على جميع ميزات الوسائط:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => EnhancedAudioRoomScreen(
      roomId: roomId,
      currentUser: currentUser,
    ),
  ),
);
```

### 2. أوضاع عرض الوسائط

- **Minimized**: عرض مصغر في أعلى الشاشة
- **Compact**: عرض مضغوط مع أدوات تحكم أساسية
- **Expanded**: عرض موسع مع جميع الميزات
- **Fullscreen**: ملء الشاشة للفيديوهات

## الأمان والصلاحيات

### 1. صلاحيات الغرفة
- **مالك الغرفة**: تحكم كامل في الوسائط
- **المشرفون**: تحكم محدود
- **المستخدمون**: مشاهدة فقط

### 2. تصفية المحتوى
- فلترة الكلمات غير المناسبة
- التحقق من أنواع الملفات المدعومة
- حدود حجم الملفات (50MB)

### 3. المصادقة
- جميع API endpoints تتطلب مصادقة Firebase
- التحقق من صلاحيات المستخدم لكل عملية

## الأداء والتحسين

### 1. تحسين الشبكة
- ضغط الملفات الصوتية
- تخزين مؤقت للبيانات الوصفية
- مزامنة ذكية تقلل استهلاك البيانات

### 2. تحسين الذاكرة
- تحرير موارد المشغلات عند عدم الاستخدام
- إدارة ذكية لقائمة التشغيل
- تنظيف دوري للملفات المؤقتة

### 3. تجربة المستخدم
- تحميل تدريجي للمحتوى
- واجهات متجاوبة ومتحركة
- معالجة أخطاء شاملة

## استكشاف الأخطاء

### 1. مشاكل شائعة

#### فشل تشغيل YouTube
```dart
// التحقق من صحة الرابط
final videoId = YoutubePlayer.convertUrlToId(url);
if (videoId == null) {
  throw Exception('رابط YouTube غير صحيح');
}
```

#### مشاكل رفع الملفات
```dart
// التحقق من الصلاحيات
final permission = await Permission.storage.request();
if (!permission.isGranted) {
  throw Exception('يجب منح صلاحية الوصول للملفات');
}
```

#### مشاكل المزامنة
```dart
// إعادة الاتصال بـ Socket
await socketService.reconnect();
await mediaService.loadActiveContent();
```

### 2. سجلات التشخيص

تفعيل السجلات المفصلة:

```dart
// في main.dart
void main() {
  if (kDebugMode) {
    Logger.root.level = Level.ALL;
  }
  runApp(MyApp());
}
```

## التطوير المستقبلي

### 1. ميزات مخططة
- دعم البث المباشر
- تسجيل الجلسات الصوتية
- مشاركة الشاشة
- تأثيرات صوتية متقدمة

### 2. تحسينات تقنية
- دعم WebRTC للجودة العالية
- تشفير المحتوى الحساس
- تحليلات استخدام متقدمة
- دعم منصات إضافية (Spotify, SoundCloud)

## الدعم والمساعدة

للحصول على المساعدة أو الإبلاغ عن مشاكل:

1. راجع هذا الدليل أولاً
2. تحقق من سجلات الأخطاء
3. تأكد من تحديث جميع التبعيات
4. اتصل بفريق التطوير مع تفاصيل المشكلة

---

**ملاحظة**: هذا النظام في مرحلة التطوير النشط. يُنصح بمراجعة هذا الدليل بانتظام للحصول على آخر التحديثات والميزات الجديدة.

