import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/media_content_model.dart';
import 'media_service.dart';

/// خدمة إدارة قائمة انتظار الوسائط
class MediaQueueService extends ChangeNotifier {
  static final MediaQueueService _instance = MediaQueueService._internal();
  factory MediaQueueService() => _instance;
  MediaQueueService._internal();

  // قائمة الانتظار الحالية
  List<MediaContent> _queue = [];
  List<MediaContent> get queue => List.unmodifiable(_queue);

  // الفهرس الحالي في القائمة
  int _currentIndex = -1;
  int get currentIndex => _currentIndex;

  // المحتوى الحالي
  MediaContent? get currentContent => 
      _currentIndex >= 0 && _currentIndex < _queue.length 
          ? _queue[_currentIndex] 
          : null;

  // إعدادات التشغيل
  bool _isShuffleEnabled = false;
  bool get isShuffleEnabled => _isShuffleEnabled;

  RepeatMode _repeatMode = RepeatMode.off;
  RepeatMode get repeatMode => _repeatMode;

  bool _autoPlay = true;
  bool get autoPlay => _autoPlay;

  // قائمة الخلط
  List<int> _shuffleIndices = [];
  int _shufflePosition = -1;

  // التاريخ والإحصائيات
  List<MediaContent> _history = [];
  List<MediaContent> get history => List.unmodifiable(_history);

  Map<String, int> _playCount = {};
  Map<String, int> get playCount => Map.unmodifiable(_playCount);

  // خدمة الوسائط
  MediaService? _mediaService;

  /// تهيئة الخدمة
  void initialize(MediaService mediaService) {
    _mediaService = mediaService;
  }

  /// إضافة محتوى إلى القائمة
  void addToQueue(MediaContent content, {bool playNow = false}) {
    if (!_queue.any((item) => item.contentId == content.contentId)) {
      _queue.add(content);
      
      if (playNow) {
        _currentIndex = _queue.length - 1;
        _updateShuffleIndices();
        _playCurrentContent();
      } else if (_currentIndex == -1 && _queue.isNotEmpty) {
        _currentIndex = 0;
        _updateShuffleIndices();
      }
      
      notifyListeners();
    }
  }

  /// إضافة قائمة محتوى
  void addMultipleToQueue(List<MediaContent> contents, {bool playFirst = false}) {
    final newContents = contents.where(
      (content) => !_queue.any((item) => item.contentId == content.contentId)
    ).toList();
    
    if (newContents.isNotEmpty) {
      _queue.addAll(newContents);
      
      if (playFirst && newContents.isNotEmpty) {
        _currentIndex = _queue.length - newContents.length;
        _updateShuffleIndices();
        _playCurrentContent();
      } else if (_currentIndex == -1 && _queue.isNotEmpty) {
        _currentIndex = 0;
        _updateShuffleIndices();
      }
      
      notifyListeners();
    }
  }

  /// إدراج محتوى في موضع محدد
  void insertAtPosition(MediaContent content, int position) {
    if (!_queue.any((item) => item.contentId == content.contentId)) {
      final insertIndex = position.clamp(0, _queue.length);
      _queue.insert(insertIndex, content);
      
      // تحديث الفهرس الحالي إذا لزم الأمر
      if (insertIndex <= _currentIndex) {
        _currentIndex++;
      }
      
      _updateShuffleIndices();
      notifyListeners();
    }
  }

  /// تشغيل محتوى محدد
  void playContent(String contentId) {
    final index = _queue.indexWhere((content) => content.contentId == contentId);
    if (index != -1) {
      _currentIndex = index;
      _updateShufflePosition();
      _playCurrentContent();
      notifyListeners();
    }
  }

  /// تشغيل محتوى في موضع محدد
  void playAtIndex(int index) {
    if (index >= 0 && index < _queue.length) {
      _currentIndex = index;
      _updateShufflePosition();
      _playCurrentContent();
      notifyListeners();
    }
  }

  /// الانتقال للمحتوى التالي
  Future<bool> playNext() async {
    final nextIndex = _getNextIndex();
    if (nextIndex != -1) {
      _currentIndex = nextIndex;
      _playCurrentContent();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// الانتقال للمحتوى السابق
  Future<bool> playPrevious() async {
    final previousIndex = _getPreviousIndex();
    if (previousIndex != -1) {
      _currentIndex = previousIndex;
      _playCurrentContent();
      notifyListeners();
      return true;
    }
    return false;
  }

  /// إزالة محتوى من القائمة
  void removeFromQueue(String contentId) {
    final index = _queue.indexWhere((content) => content.contentId == contentId);
    if (index != -1) {
      _queue.removeAt(index);
      
      // تحديث الفهرس الحالي
      if (index < _currentIndex) {
        _currentIndex--;
      } else if (index == _currentIndex) {
        if (_currentIndex >= _queue.length) {
          _currentIndex = _queue.isNotEmpty ? _queue.length - 1 : -1;
        }
        // إذا كان المحتوى المحذوف هو المحتوى الحالي، توقف عن التشغيل
        _mediaService?.stopContent();
      }
      
      _updateShuffleIndices();
      notifyListeners();
    }
  }

  /// نقل محتوى في القائمة
  void moveInQueue(int oldIndex, int newIndex) {
    if (oldIndex >= 0 && oldIndex < _queue.length && 
        newIndex >= 0 && newIndex < _queue.length) {
      
      final content = _queue.removeAt(oldIndex);
      _queue.insert(newIndex, content);
      
      // تحديث الفهرس الحالي
      if (oldIndex == _currentIndex) {
        _currentIndex = newIndex;
      } else if (oldIndex < _currentIndex && newIndex >= _currentIndex) {
        _currentIndex--;
      } else if (oldIndex > _currentIndex && newIndex <= _currentIndex) {
        _currentIndex++;
      }
      
      _updateShuffleIndices();
      notifyListeners();
    }
  }

  /// مسح القائمة
  void clearQueue() {
    _queue.clear();
    _currentIndex = -1;
    _shuffleIndices.clear();
    _shufflePosition = -1;
    _mediaService?.stopContent();
    notifyListeners();
  }

  /// تبديل وضع الخلط
  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    _updateShuffleIndices();
    notifyListeners();
  }

  /// تغيير وضع التكرار
  void setRepeatMode(RepeatMode mode) {
    _repeatMode = mode;
    notifyListeners();
  }

  /// تبديل وضع التكرار
  void toggleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    notifyListeners();
  }

  /// تبديل التشغيل التلقائي
  void toggleAutoPlay() {
    _autoPlay = !_autoPlay;
    notifyListeners();
  }

  /// الحصول على الفهرس التالي
  int _getNextIndex() {
    if (_queue.isEmpty) return -1;

    if (_repeatMode == RepeatMode.one) {
      return _currentIndex;
    }

    if (_isShuffleEnabled) {
      if (_shufflePosition < _shuffleIndices.length - 1) {
        _shufflePosition++;
        return _shuffleIndices[_shufflePosition];
      } else if (_repeatMode == RepeatMode.all) {
        _shufflePosition = 0;
        return _shuffleIndices[_shufflePosition];
      }
    } else {
      if (_currentIndex < _queue.length - 1) {
        return _currentIndex + 1;
      } else if (_repeatMode == RepeatMode.all) {
        return 0;
      }
    }

    return -1;
  }

  /// الحصول على الفهرس السابق
  int _getPreviousIndex() {
    if (_queue.isEmpty) return -1;

    if (_repeatMode == RepeatMode.one) {
      return _currentIndex;
    }

    if (_isShuffleEnabled) {
      if (_shufflePosition > 0) {
        _shufflePosition--;
        return _shuffleIndices[_shufflePosition];
      } else if (_repeatMode == RepeatMode.all) {
        _shufflePosition = _shuffleIndices.length - 1;
        return _shuffleIndices[_shufflePosition];
      }
    } else {
      if (_currentIndex > 0) {
        return _currentIndex - 1;
      } else if (_repeatMode == RepeatMode.all) {
        return _queue.length - 1;
      }
    }

    return -1;
  }

  /// تحديث فهارس الخلط
  void _updateShuffleIndices() {
    if (_queue.isEmpty) {
      _shuffleIndices.clear();
      _shufflePosition = -1;
      return;
    }

    _shuffleIndices = List.generate(_queue.length, (index) => index);
    
    if (_isShuffleEnabled) {
      // خلط القائمة مع الحفاظ على المحتوى الحالي في المقدمة
      if (_currentIndex != -1) {
        _shuffleIndices.remove(_currentIndex);
        _shuffleIndices.shuffle(Random());
        _shuffleIndices.insert(0, _currentIndex);
        _shufflePosition = 0;
      } else {
        _shuffleIndices.shuffle(Random());
        _shufflePosition = -1;
      }
    } else {
      _shufflePosition = _currentIndex;
    }
  }

  /// تحديث موضع الخلط
  void _updateShufflePosition() {
    if (_isShuffleEnabled && _currentIndex != -1) {
      _shufflePosition = _shuffleIndices.indexOf(_currentIndex);
    } else {
      _shufflePosition = _currentIndex;
    }
  }

  /// تشغيل المحتوى الحالي
  void _playCurrentContent() {
    final content = currentContent;
    if (content != null && _mediaService != null) {
      _mediaService!.startContent(content.contentId);
      _addToHistory(content);
      _incrementPlayCount(content.contentId);
    }
  }

  /// إضافة إلى التاريخ
  void _addToHistory(MediaContent content) {
    _history.removeWhere((item) => item.contentId == content.contentId);
    _history.insert(0, content);
    
    // الاحتفاظ بآخر 50 عنصر فقط
    if (_history.length > 50) {
      _history = _history.take(50).toList();
    }
  }

  /// زيادة عداد التشغيل
  void _incrementPlayCount(String contentId) {
    _playCount[contentId] = (_playCount[contentId] ?? 0) + 1;
  }

  /// الحصول على المحتوى الأكثر تشغيلاً
  List<MediaContent> getMostPlayed({int limit = 10}) {
    final sortedEntries = _playCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final result = <MediaContent>[];
    for (final entry in sortedEntries.take(limit)) {
      final content = _queue.firstWhere(
        (item) => item.contentId == entry.key,
        orElse: () => _history.firstWhere(
          (item) => item.contentId == entry.key,
          orElse: () => MediaContent(
            contentId: entry.key,
            type: 'unknown',
            title: 'محتوى محذوف',
            description: '',
            status: 'deleted',
            playbackState: PlaybackState(
              isPlaying: false,
              currentPosition: 0,
              playbackSpeed: 1.0,
              volume: 100,
              lastUpdated: DateTime.now(),
            ),
            stats: MediaStats(
              playCount: entry.value,
              likeCount: 0,
              skipCount: 0,
              totalPlayTime: 0,
            ),
            metadata: MediaMetadata(
              addedBy: '',
              addedAt: DateTime.now(),
              tags: [],
              permissions: {},
            ),
          ),
        ),
      );
      result.add(content);
    }
    
    return result;
  }

  /// إنشاء قائمة تشغيل ذكية
  List<MediaContent> createSmartPlaylist({
    String? type,
    List<String>? tags,
    int? minPlayCount,
    Duration? maxDuration,
    int limit = 20,
  }) {
    var filtered = _queue.where((content) {
      // تصفية حسب النوع
      if (type != null && content.type != type) return false;
      
      // تصفية حسب العلامات
      if (tags != null && tags.isNotEmpty) {
        final contentTags = content.metadata.tags;
        if (!tags.any((tag) => contentTags.contains(tag))) return false;
      }
      
      // تصفية حسب عدد مرات التشغيل
      if (minPlayCount != null) {
        final playCount = _playCount[content.contentId] ?? 0;
        if (playCount < minPlayCount) return false;
      }
      
      // تصفية حسب المدة
      if (maxDuration != null) {
        final duration = content.type == 'youtube' 
            ? content.youtubeData?.duration ?? 0
            : content.audioData?.duration ?? 0;
        if (duration > maxDuration.inSeconds) return false;
      }
      
      return true;
    }).toList();
    
    // ترتيب حسب الشعبية
    filtered.sort((a, b) {
      final aPlayCount = _playCount[a.contentId] ?? 0;
      final bPlayCount = _playCount[b.contentId] ?? 0;
      return bPlayCount.compareTo(aPlayCount);
    });
    
    return filtered.take(limit).toList();
  }

  /// حفظ حالة القائمة
  Map<String, dynamic> saveState() {
    return {
      'queue': _queue.map((content) => content.toJson()).toList(),
      'currentIndex': _currentIndex,
      'isShuffleEnabled': _isShuffleEnabled,
      'repeatMode': _repeatMode.index,
      'autoPlay': _autoPlay,
      'shuffleIndices': _shuffleIndices,
      'shufflePosition': _shufflePosition,
      'history': _history.map((content) => content.toJson()).toList(),
      'playCount': _playCount,
    };
  }

  /// استعادة حالة القائمة
  void restoreState(Map<String, dynamic> state) {
    try {
      _queue = (state['queue'] as List)
          .map((json) => MediaContent.fromJson(json))
          .toList();
      
      _currentIndex = state['currentIndex'] ?? -1;
      _isShuffleEnabled = state['isShuffleEnabled'] ?? false;
      _repeatMode = RepeatMode.values[state['repeatMode'] ?? 0];
      _autoPlay = state['autoPlay'] ?? true;
      _shuffleIndices = List<int>.from(state['shuffleIndices'] ?? []);
      _shufflePosition = state['shufflePosition'] ?? -1;
      
      _history = (state['history'] as List? ?? [])
          .map((json) => MediaContent.fromJson(json))
          .toList();
      
      _playCount = Map<String, int>.from(state['playCount'] ?? {});
      
      notifyListeners();
    } catch (e) {
      debugPrint('خطأ في استعادة حالة القائمة: $e');
    }
  }

  /// معالجة انتهاء التشغيل
  void onPlaybackEnded() {
    if (_autoPlay) {
      playNext();
    }
  }

  /// إعادة تعيين الخدمة
  void reset() {
    _queue.clear();
    _currentIndex = -1;
    _isShuffleEnabled = false;
    _repeatMode = RepeatMode.off;
    _autoPlay = true;
    _shuffleIndices.clear();
    _shufflePosition = -1;
    _history.clear();
    _playCount.clear();
    notifyListeners();
  }
}

/// أوضاع التكرار
enum RepeatMode {
  off,    // بدون تكرار
  all,    // تكرار جميع الأغاني
  one,    // تكرار الأغنية الحالية
}

/// معلومات قائمة التشغيل
class PlaylistInfo {
  final String id;
  final String name;
  final String description;
  final List<String> contentIds;
  final DateTime createdAt;
  final DateTime updatedAt;

  PlaylistInfo({
    required this.id,
    required this.name,
    required this.description,
    required this.contentIds,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PlaylistInfo.fromJson(Map<String, dynamic> json) {
    return PlaylistInfo(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      contentIds: List<String>.from(json['contentIds'] ?? []),
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'contentIds': contentIds,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

