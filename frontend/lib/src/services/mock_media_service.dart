import 'dart:async';
import 'dart:math';
import '../models/media_content_model.dart';

/// خدمة الوسائط التجريبية - محاكاة تشغيل YouTube والملفات الصوتية
class MockMediaService {
  static final MockMediaService _instance = MockMediaService._internal();
  factory MockMediaService() => _instance;
  MockMediaService._internal();

  // حالة التشغيل
  bool _isPlaying = false;
  bool _isPaused = false;
  double _currentPosition = 0.0;
  double _duration = 0.0;
  double _volume = 0.8;
  MediaContentModel? _currentMedia;
  
  // قائمة الانتظار
  final List<MediaContentModel> _queue = [];
  int _currentIndex = 0;

  // تيارات البيانات
  final StreamController<bool> _playingController = StreamController<bool>.broadcast();
  final StreamController<double> _positionController = StreamController<double>.broadcast();
  final StreamController<MediaContentModel?> _mediaController = StreamController<MediaContentModel?>.broadcast();
  final StreamController<List<MediaContentModel>> _queueController = StreamController<List<MediaContentModel>>.broadcast();

  // Timer للمحاكاة
  Timer? _progressTimer;

  /// تيارات البيانات العامة
  Stream<bool> get isPlayingStream => _playingController.stream;
  Stream<double> get positionStream => _positionController.stream;
  Stream<MediaContentModel?> get currentMediaStream => _mediaController.stream;
  Stream<List<MediaContentModel>> get queueStream => _queueController.stream;

  /// الحصول على الحالة الحالية
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  double get currentPosition => _currentPosition;
  double get duration => _duration;
  double get volume => _volume;
  MediaContentModel? get currentMedia => _currentMedia;
  List<MediaContentModel> get queue => List.unmodifiable(_queue);

  /// فيديوهات YouTube تجريبية
  final List<Map<String, dynamic>> _demoYouTubeVideos = [
    {
      'id': 'yt_001',
      'title': 'أغنية عربية كلاسيكية - فيروز',
      'artist': 'فيروز',
      'duration': 245.0,
      'thumbnail': 'https://via.placeholder.com/320x180/FF6B6B/FFFFFF?text=فيروز',
      'url': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ',
    },
    {
      'id': 'yt_002', 
      'title': 'موسيقى هادئة للاسترخاء',
      'artist': 'موسيقى هادئة',
      'duration': 180.0,
      'thumbnail': 'https://via.placeholder.com/320x180/4ECDC4/FFFFFF?text=استرخاء',
      'url': 'https://www.youtube.com/watch?v=relaxing123',
    },
    {
      'id': 'yt_003',
      'title': 'أغاني عربية حديثة',
      'artist': 'فنانين متنوعين',
      'duration': 200.0,
      'thumbnail': 'https://via.placeholder.com/320x180/45B7D1/FFFFFF?text=حديثة',
      'url': 'https://www.youtube.com/watch?v=modern456',
    },
  ];

  /// ملفات صوتية تجريبية
  final List<Map<String, dynamic>> _demoAudioFiles = [
    {
      'id': 'audio_001',
      'title': 'أغنية محلية 1.mp3',
      'artist': 'مجهول',
      'duration': 210.0,
      'thumbnail': 'https://via.placeholder.com/150/F7DC6F/FFFFFF?text=MP3',
      'filePath': '/demo/audio1.mp3',
      'fileSize': 5242880, // 5MB
    },
    {
      'id': 'audio_002',
      'title': 'موسيقى تصويرية.wav',
      'artist': 'موسيقى تصويرية',
      'duration': 156.0,
      'thumbnail': 'https://via.placeholder.com/150/BB8FCE/FFFFFF?text=WAV',
      'filePath': '/demo/soundtrack.wav',
      'fileSize': 15728640, // 15MB
    },
    {
      'id': 'audio_003',
      'title': 'بودكاست عربي.aac',
      'artist': 'بودكاست',
      'duration': 1800.0, // 30 دقيقة
      'thumbnail': 'https://via.placeholder.com/150/85C1E9/FFFFFF?text=AAC',
      'filePath': '/demo/podcast.aac',
      'fileSize': 25165824, // 24MB
    },
  ];

  /// تهيئة البيانات التجريبية
  void initializeDemoData() {
    // إضافة محتوى تجريبي لقائمة الانتظار
    _queue.addAll([
      ..._demoYouTubeVideos.map((data) => MediaContentModel.fromJson({...data, 'type': 'youtube'})),
      ..._demoAudioFiles.map((data) => MediaContentModel.fromJson({...data, 'type': 'audio_file'})),
    ]);
    
    _queueController.add(_queue);
  }

  /// إضافة فيديو YouTube
  Future<bool> addYouTubeVideo(String url) async {
    try {
      // محاكاة تأخير الشبكة
      await Future.delayed(const Duration(seconds: 2));

      // محاكاة استخراج معلومات الفيديو
      final videoData = _demoYouTubeVideos[Random().nextInt(_demoYouTubeVideos.length)];
      final media = MediaContentModel.fromJson({
        ...videoData,
        'type': 'youtube',
        'url': url,
        'addedAt': DateTime.now().toIso8601String(),
      });

      _queue.add(media);
      _queueController.add(_queue);
      
      return true;
    } catch (e) {
      print('خطأ في إضافة فيديو YouTube: $e');
      return false;
    }
  }

  /// إضافة ملف صوتي
  Future<bool> addAudioFile(String filePath, {String? fileName}) async {
    try {
      // محاكاة تأخير رفع الملف
      await Future.delayed(const Duration(seconds: 3));

      final audioData = _demoAudioFiles[Random().nextInt(_demoAudioFiles.length)];
      final media = MediaContentModel.fromJson({
        ...audioData,
        'type': 'audio_file',
        'title': fileName ?? audioData['title'],
        'filePath': filePath,
        'addedAt': DateTime.now().toIso8601String(),
      });

      _queue.add(media);
      _queueController.add(_queue);
      
      return true;
    } catch (e) {
      print('خطأ في إضافة ملف صوتي: $e');
      return false;
    }
  }

  /// تشغيل محتوى
  Future<bool> play([MediaContentModel? media]) async {
    try {
      if (media != null) {
        _currentMedia = media;
        _currentIndex = _queue.indexOf(media);
        _duration = media.duration ?? 180.0;
        _currentPosition = 0.0;
      } else if (_currentMedia == null && _queue.isNotEmpty) {
        _currentMedia = _queue.first;
        _currentIndex = 0;
        _duration = _currentMedia!.duration ?? 180.0;
        _currentPosition = 0.0;
      }

      if (_currentMedia == null) return false;

      _isPlaying = true;
      _isPaused = false;
      
      // بدء محاكاة التقدم
      _startProgressSimulation();
      
      // إشعار المستمعين
      _playingController.add(_isPlaying);
      _mediaController.add(_currentMedia);
      
      return true;
    } catch (e) {
      print('خطأ في التشغيل: $e');
      return false;
    }
  }

  /// إيقاف مؤقت
  Future<void> pause() async {
    _isPlaying = false;
    _isPaused = true;
    _stopProgressSimulation();
    _playingController.add(_isPlaying);
  }

  /// استئناف التشغيل
  Future<void> resume() async {
    if (_currentMedia != null) {
      _isPlaying = true;
      _isPaused = false;
      _startProgressSimulation();
      _playingController.add(_isPlaying);
    }
  }

  /// إيقاف التشغيل
  Future<void> stop() async {
    _isPlaying = false;
    _isPaused = false;
    _currentPosition = 0.0;
    _stopProgressSimulation();
    
    _playingController.add(_isPlaying);
    _positionController.add(_currentPosition);
  }

  /// التقديم لموضع معين
  Future<void> seekTo(double position) async {
    if (_currentMedia != null && position >= 0 && position <= _duration) {
      _currentPosition = position;
      _positionController.add(_currentPosition);
    }
  }

  /// تغيير مستوى الصوت
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
  }

  /// التقديم السريع
  Future<void> fastForward([double seconds = 10.0]) async {
    await seekTo(_currentPosition + seconds);
  }

  /// الترجيع السريع
  Future<void> rewind([double seconds = 10.0]) async {
    await seekTo(_currentPosition - seconds);
  }

  /// التالي
  Future<bool> next() async {
    if (_queue.isEmpty) return false;
    
    _currentIndex = (_currentIndex + 1) % _queue.length;
    return await play(_queue[_currentIndex]);
  }

  /// السابق
  Future<bool> previous() async {
    if (_queue.isEmpty) return false;
    
    _currentIndex = (_currentIndex - 1 + _queue.length) % _queue.length;
    return await play(_queue[_currentIndex]);
  }

  /// إزالة من قائمة الانتظار
  Future<void> removeFromQueue(String mediaId) async {
    _queue.removeWhere((media) => media.id == mediaId);
    _queueController.add(_queue);
    
    // إذا كان المحتوى المحذوف هو المشغل حالياً
    if (_currentMedia?.id == mediaId) {
      if (_queue.isNotEmpty) {
        await next();
      } else {
        await stop();
        _currentMedia = null;
        _mediaController.add(null);
      }
    }
  }

  /// ترتيب قائمة الانتظار
  Future<void> reorderQueue(int oldIndex, int newIndex) async {
    if (oldIndex < _queue.length && newIndex < _queue.length) {
      final item = _queue.removeAt(oldIndex);
      _queue.insert(newIndex, item);
      _queueController.add(_queue);
    }
  }

  /// خلط قائمة الانتظار
  Future<void> shuffleQueue() async {
    if (_queue.length > 1) {
      _queue.shuffle();
      _currentIndex = _currentMedia != null ? _queue.indexOf(_currentMedia!) : 0;
      _queueController.add(_queue);
    }
  }

  /// مسح قائمة الانتظار
  Future<void> clearQueue() async {
    await stop();
    _queue.clear();
    _currentMedia = null;
    _currentIndex = 0;
    
    _queueController.add(_queue);
    _mediaController.add(null);
  }

  /// بدء محاكاة التقدم
  void _startProgressSimulation() {
    _stopProgressSimulation();
    
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isPlaying && _currentMedia != null) {
        _currentPosition += 1.0;
        
        if (_currentPosition >= _duration) {
          // انتهى المحتوى، تشغيل التالي
          _currentPosition = _duration;
          timer.cancel();
          next();
        }
        
        _positionController.add(_currentPosition);
      }
    });
  }

  /// إيقاف محاكاة التقدم
  void _stopProgressSimulation() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  /// تنسيق الوقت
  String formatDuration(double seconds) {
    final duration = Duration(seconds: seconds.round());
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// الحصول على محتوى تجريبي عشوائي
  MediaContentModel getRandomDemoContent() {
    final allContent = [
      ..._demoYouTubeVideos.map((data) => MediaContentModel.fromJson({...data, 'type': 'youtube'})),
      ..._demoAudioFiles.map((data) => MediaContentModel.fromJson({...data, 'type': 'audio_file'})),
    ];
    
    return allContent[Random().nextInt(allContent.length)];
  }

  /// تنظيف الموارد
  void dispose() {
    _stopProgressSimulation();
    _playingController.close();
    _positionController.close();
    _mediaController.close();
    _queueController.close();
  }
}

