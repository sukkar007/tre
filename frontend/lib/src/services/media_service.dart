import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/media_content_model.dart';
import '../utils/app_constants.dart';
import 'socket_service.dart';
import 'auth_service.dart';

/// خدمة إدارة الوسائط والمزامنة
/// تدير تشغيل YouTube والموسيقى في الغرف الصوتية
class MediaService extends ChangeNotifier {
  static final MediaService _instance = MediaService._internal();
  factory MediaService() => _instance;
  MediaService._internal();

  // YouTube Player Controller
  YoutubePlayerController? _youtubeController;
  YoutubePlayerController? get youtubeController => _youtubeController;

  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioPlayer get audioPlayer => _audioPlayer;

  // Current media state
  MediaContent? _currentContent;
  MediaContent? get currentContent => _currentContent;

  bool _isPlaying = false;
  bool get isPlaying => _isPlaying;

  double _currentPosition = 0.0;
  double get currentPosition => _currentPosition;

  double _duration = 0.0;
  double get duration => _duration;

  double _volume = 1.0;
  double get volume => _volume;

  double _playbackSpeed = 1.0;
  double get playbackSpeed => _playbackSpeed;

  String? _currentRoomId;
  String? get currentRoomId => _currentRoomId;

  List<MediaContent> _roomPlaylist = [];
  List<MediaContent> get roomPlaylist => _roomPlaylist;

  // Sync timer
  Timer? _syncTimer;
  Timer? _positionTimer;

  // Socket listeners
  StreamSubscription? _mediaSocketSubscription;

  /// تهيئة الخدمة للغرفة
  Future<void> initializeForRoom(String roomId) async {
    try {
      _currentRoomId = roomId;
      
      // إعداد مستمعي Socket
      _setupSocketListeners();
      
      // تحميل المحتوى النشط
      await loadActiveContent();
      
      // تحميل قائمة التشغيل
      await loadRoomPlaylist();
      
      // إعداد مستمعي Audio Player
      _setupAudioPlayerListeners();
      
      debugPrint('تم تهيئة خدمة الوسائط للغرفة: $roomId');
      
    } catch (e) {
      debugPrint('خطأ في تهيئة خدمة الوسائط: $e');
      rethrow;
    }
  }

  /// إعداد مستمعي Socket
  void _setupSocketListeners() {
    final socketService = SocketService();
    
    _mediaSocketSubscription?.cancel();
    _mediaSocketSubscription = socketService.socket?.listen((event) {
      final data = json.decode(event);
      
      switch (data['type']) {
        case 'media_started':
          _handleMediaStarted(data['data']);
          break;
        case 'media_paused':
          _handleMediaPaused(data['data']);
          break;
        case 'media_stopped':
          _handleMediaStopped(data['data']);
          break;
        case 'media_seeked':
          _handleMediaSeeked(data['data']);
          break;
        case 'media_volume_changed':
          _handleVolumeChanged(data['data']);
          break;
        case 'media_sync':
          _handleMediaSync(data['data']);
          break;
        case 'media_added':
          _handleMediaAdded(data['data']);
          break;
        case 'media_deleted':
          _handleMediaDeleted(data['data']);
          break;
      }
    });
  }

  /// إعداد مستمعي Audio Player
  void _setupAudioPlayerListeners() {
    _audioPlayer.onPositionChanged.listen((position) {
      _currentPosition = position.inSeconds.toDouble();
      notifyListeners();
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      _duration = duration.inSeconds.toDouble();
      notifyListeners();
    });

    _audioPlayer.onPlayerStateChanged.listen((state) {
      _isPlaying = state == PlayerState.playing;
      notifyListeners();
    });
  }

  /// تحميل المحتوى النشط
  Future<void> loadActiveContent() async {
    try {
      if (_currentRoomId == null) return;

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/media/active/$_currentRoomId'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['content'] != null) {
          _currentContent = MediaContent.fromJson(data['content']);
          await _initializePlayer();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('خطأ في تحميل المحتوى النشط: $e');
    }
  }

  /// تحميل قائمة تشغيل الغرفة
  Future<void> loadRoomPlaylist() async {
    try {
      if (_currentRoomId == null) return;

      final response = await http.get(
        Uri.parse('${AppConstants.baseUrl}/api/media/room/$_currentRoomId'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _roomPlaylist = (data['contents'] as List)
            .map((item) => MediaContent.fromJson(item))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('خطأ في تحميل قائمة التشغيل: $e');
    }
  }

  /// تهيئة المشغل حسب نوع المحتوى
  Future<void> _initializePlayer() async {
    if (_currentContent == null) return;

    try {
      if (_currentContent!.type == 'youtube') {
        await _initializeYouTubePlayer();
      } else if (_currentContent!.type == 'audio_file') {
        await _initializeAudioPlayer();
      }
    } catch (e) {
      debugPrint('خطأ في تهيئة المشغل: $e');
    }
  }

  /// تهيئة مشغل YouTube
  Future<void> _initializeYouTubePlayer() async {
    if (_currentContent?.youtubeData?.videoId == null) return;

    _youtubeController?.dispose();
    
    _youtubeController = YoutubePlayerController(
      initialVideoId: _currentContent!.youtubeData!.videoId,
      flags: YoutubePlayerFlags(
        autoPlay: _currentContent!.playbackState.isPlaying,
        mute: false,
        loop: false,
        startAt: _currentContent!.playbackState.currentPosition.toInt(),
      ),
    );

    // إعداد مستمعي YouTube
    _youtubeController!.addListener(() {
      if (_youtubeController!.value.isReady) {
        _duration = _youtubeController!.metadata.duration.inSeconds.toDouble();
        _currentPosition = _youtubeController!.value.position.inSeconds.toDouble();
        _isPlaying = _youtubeController!.value.isPlaying;
        notifyListeners();
      }
    });
  }

  /// تهيئة مشغل الصوت
  Future<void> _initializeAudioPlayer() async {
    if (_currentContent?.audioData?.fileUrl == null) return;

    await _audioPlayer.setSource(UrlSource(_currentContent!.audioData!.fileUrl));
    
    if (_currentContent!.playbackState.isPlaying) {
      await _audioPlayer.resume();
    }
    
    await _audioPlayer.seek(Duration(
      seconds: _currentContent!.playbackState.currentPosition.toInt()
    ));
  }

  /// بدء تشغيل محتوى
  Future<bool> startContent(String contentId, {double startPosition = 0}) async {
    try {
      if (_currentRoomId == null) return false;

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/media/start'),
        headers: await _getAuthHeaders(),
        body: json.encode({
          'roomId': _currentRoomId,
          'contentId': contentId,
          'startPosition': startPosition,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('خطأ في بدء التشغيل: $e');
      return false;
    }
  }

  /// إيقاف التشغيل مؤقتاً
  Future<bool> pauseContent() async {
    try {
      if (_currentRoomId == null || _currentContent == null) return false;

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/media/pause'),
        headers: await _getAuthHeaders(),
        body: json.encode({
          'roomId': _currentRoomId,
          'contentId': _currentContent!.contentId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('خطأ في إيقاف التشغيل: $e');
      return false;
    }
  }

  /// إيقاف التشغيل نهائياً
  Future<bool> stopContent() async {
    try {
      if (_currentRoomId == null) return false;

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/media/stop'),
        headers: await _getAuthHeaders(),
        body: json.encode({
          'roomId': _currentRoomId,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('خطأ في إيقاف التشغيل: $e');
      return false;
    }
  }

  /// تغيير موقع التشغيل
  Future<bool> seekTo(double position) async {
    try {
      if (_currentRoomId == null || _currentContent == null) return false;

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/media/seek'),
        headers: await _getAuthHeaders(),
        body: json.encode({
          'roomId': _currentRoomId,
          'contentId': _currentContent!.contentId,
          'position': position,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('خطأ في تغيير موقع التشغيل: $e');
      return false;
    }
  }

  /// تغيير مستوى الصوت
  Future<bool> changeVolume(double volume) async {
    try {
      if (_currentRoomId == null || _currentContent == null) return false;

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/media/volume'),
        headers: await _getAuthHeaders(),
        body: json.encode({
          'roomId': _currentRoomId,
          'contentId': _currentContent!.contentId,
          'volume': volume,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('خطأ في تغيير مستوى الصوت: $e');
      return false;
    }
  }

  /// إضافة فيديو YouTube
  Future<bool> addYouTubeVideo(String videoUrl) async {
    try {
      if (_currentRoomId == null) return false;

      final videoId = YoutubePlayer.convertUrlToId(videoUrl);
      if (videoId == null) {
        throw Exception('رابط YouTube غير صحيح');
      }

      // الحصول على معلومات الفيديو
      final videoInfo = await _getYouTubeVideoInfo(videoId);

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/media/youtube/add'),
        headers: await _getAuthHeaders(),
        body: json.encode({
          'roomId': _currentRoomId,
          'videoId': videoId,
          'videoInfo': videoInfo,
        }),
      );

      if (response.statusCode == 200) {
        await loadRoomPlaylist();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('خطأ في إضافة فيديو YouTube: $e');
      return false;
    }
  }

  /// إضافة ملف صوتي
  Future<bool> addAudioFile() async {
    try {
      if (_currentRoomId == null) return false;

      // طلب الصلاحيات
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        throw Exception('يجب منح صلاحية الوصول للملفات');
      }

      // اختيار الملف
      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) return false;

      final file = result.files.first;
      
      // رفع الملف
      final uploadResult = await _uploadAudioFile(File(file.path!));
      if (uploadResult == null) return false;

      final response = await http.post(
        Uri.parse('${AppConstants.baseUrl}/api/media/audio/add'),
        headers: await _getAuthHeaders(),
        body: json.encode({
          'roomId': _currentRoomId,
          'fileInfo': {
            'fileName': file.name,
            'fileSize': file.size,
            'duration': uploadResult['duration'],
            'fileUrl': uploadResult['url'],
          },
        }),
      );

      if (response.statusCode == 200) {
        await loadRoomPlaylist();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('خطأ في إضافة ملف صوتي: $e');
      return false;
    }
  }

  /// حذف محتوى
  Future<bool> deleteContent(String contentId) async {
    try {
      if (_currentRoomId == null) return false;

      final response = await http.delete(
        Uri.parse('${AppConstants.baseUrl}/api/media/delete'),
        headers: await _getAuthHeaders(),
        body: json.encode({
          'roomId': _currentRoomId,
          'contentId': contentId,
        }),
      );

      if (response.statusCode == 200) {
        await loadRoomPlaylist();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('خطأ في حذف المحتوى: $e');
      return false;
    }
  }

  /// معالجة أحداث Socket
  void _handleMediaStarted(Map<String, dynamic> data) async {
    _currentContent = MediaContent.fromJson(data['content']);
    await _initializePlayer();
    notifyListeners();
  }

  void _handleMediaPaused(Map<String, dynamic> data) {
    _isPlaying = false;
    _pauseCurrentPlayer();
    notifyListeners();
  }

  void _handleMediaStopped(Map<String, dynamic> data) {
    _isPlaying = false;
    _currentContent = null;
    _stopCurrentPlayer();
    notifyListeners();
  }

  void _handleMediaSeeked(Map<String, dynamic> data) {
    final position = data['position'].toDouble();
    _currentPosition = position;
    _seekCurrentPlayer(position);
    notifyListeners();
  }

  void _handleVolumeChanged(Map<String, dynamic> data) {
    _volume = data['volume'].toDouble() / 100.0;
    _setCurrentPlayerVolume(_volume);
    notifyListeners();
  }

  void _handleMediaSync(Map<String, dynamic> data) {
    if (_currentContent?.contentId == data['contentId']) {
      _currentPosition = data['currentPosition'].toDouble();
      _isPlaying = data['isPlaying'];
      _volume = data['volume'].toDouble() / 100.0;
      _playbackSpeed = data['playbackSpeed'].toDouble();
      
      // مزامنة المشغل
      _syncCurrentPlayer();
      notifyListeners();
    }
  }

  void _handleMediaAdded(Map<String, dynamic> data) {
    final content = MediaContent.fromJson(data['content']);
    _roomPlaylist.add(content);
    notifyListeners();
  }

  void _handleMediaDeleted(Map<String, dynamic> data) {
    final contentId = data['contentId'];
    _roomPlaylist.removeWhere((content) => content.contentId == contentId);
    
    if (_currentContent?.contentId == contentId) {
      _currentContent = null;
      _stopCurrentPlayer();
    }
    notifyListeners();
  }

  /// التحكم في المشغل الحالي
  void _pauseCurrentPlayer() {
    if (_youtubeController != null) {
      _youtubeController!.pause();
    } else {
      _audioPlayer.pause();
    }
  }

  void _stopCurrentPlayer() {
    if (_youtubeController != null) {
      _youtubeController!.pause();
      _youtubeController!.seekTo(Duration.zero);
    } else {
      _audioPlayer.stop();
    }
  }

  void _seekCurrentPlayer(double position) {
    final duration = Duration(seconds: position.toInt());
    if (_youtubeController != null) {
      _youtubeController!.seekTo(duration);
    } else {
      _audioPlayer.seek(duration);
    }
  }

  void _setCurrentPlayerVolume(double volume) {
    if (_youtubeController != null) {
      // YouTube player volume is controlled by system
    } else {
      _audioPlayer.setVolume(volume);
    }
  }

  void _syncCurrentPlayer() {
    // مزامنة دقيقة للمشغل مع الخادم
    final expectedPosition = Duration(seconds: _currentPosition.toInt());
    
    if (_youtubeController != null) {
      final currentPos = _youtubeController!.value.position;
      final diff = (expectedPosition.inSeconds - currentPos.inSeconds).abs();
      
      if (diff > 2) { // إذا كان الفرق أكثر من ثانيتين
        _youtubeController!.seekTo(expectedPosition);
      }
      
      if (_isPlaying && !_youtubeController!.value.isPlaying) {
        _youtubeController!.play();
      } else if (!_isPlaying && _youtubeController!.value.isPlaying) {
        _youtubeController!.pause();
      }
    } else {
      // مزامنة مشغل الصوت
      _audioPlayer.seek(expectedPosition);
      if (_isPlaying) {
        _audioPlayer.resume();
      } else {
        _audioPlayer.pause();
      }
    }
  }

  /// الحصول على معلومات فيديو YouTube
  Future<Map<String, dynamic>> _getYouTubeVideoInfo(String videoId) async {
    // يمكن استخدام YouTube Data API هنا
    // للبساطة، سنعيد معلومات أساسية
    return {
      'title': 'فيديو YouTube',
      'description': 'وصف الفيديو',
      'thumbnail': 'https://img.youtube.com/vi/$videoId/maxresdefault.jpg',
      'duration': 0, // يجب الحصول عليها من API
    };
  }

  /// رفع ملف صوتي
  Future<Map<String, dynamic>?> _uploadAudioFile(File file) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AppConstants.baseUrl}/api/media/upload'),
      );
      
      request.headers.addAll(await _getAuthHeaders());
      request.files.add(await http.MultipartFile.fromPath('audio', file.path));
      
      final response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        return json.decode(responseData);
      }
      return null;
    } catch (e) {
      debugPrint('خطأ في رفع الملف: $e');
      return null;
    }
  }

  /// الحصول على headers المصادقة
  Future<Map<String, String>> _getAuthHeaders() async {
    final authService = AuthService();
    final token = await authService.getToken();
    
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// تنظيف الموارد
  void dispose() {
    _syncTimer?.cancel();
    _positionTimer?.cancel();
    _mediaSocketSubscription?.cancel();
    _youtubeController?.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  /// إعادة تعيين الخدمة
  void reset() {
    _currentContent = null;
    _isPlaying = false;
    _currentPosition = 0.0;
    _duration = 0.0;
    _volume = 1.0;
    _playbackSpeed = 1.0;
    _currentRoomId = null;
    _roomPlaylist.clear();
    
    _syncTimer?.cancel();
    _positionTimer?.cancel();
    _mediaSocketSubscription?.cancel();
    
    _youtubeController?.dispose();
    _youtubeController = null;
    
    _audioPlayer.stop();
    
    notifyListeners();
  }
}

