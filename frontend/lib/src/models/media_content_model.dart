/// نموذج محتوى الوسائط
class MediaContent {
  final String contentId;
  final String type; // 'youtube', 'audio_file', 'playlist'
  final String title;
  final String description;
  final String status; // 'active', 'paused', 'stopped', 'queued'
  final PlaybackState playbackState;
  final MediaStats stats;
  final MediaMetadata metadata;
  final YouTubeData? youtubeData;
  final AudioData? audioData;
  final PlaylistData? playlistData;

  MediaContent({
    required this.contentId,
    required this.type,
    required this.title,
    required this.description,
    required this.status,
    required this.playbackState,
    required this.stats,
    required this.metadata,
    this.youtubeData,
    this.audioData,
    this.playlistData,
  });

  factory MediaContent.fromJson(Map<String, dynamic> json) {
    return MediaContent(
      contentId: json['contentId'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
      playbackState: PlaybackState.fromJson(json['playbackState'] ?? {}),
      stats: MediaStats.fromJson(json['stats'] ?? {}),
      metadata: MediaMetadata.fromJson(json['metadata'] ?? {}),
      youtubeData: json['youtubeData'] != null 
          ? YouTubeData.fromJson(json['youtubeData']) 
          : null,
      audioData: json['audioData'] != null 
          ? AudioData.fromJson(json['audioData']) 
          : null,
      playlistData: json['playlistData'] != null 
          ? PlaylistData.fromJson(json['playlistData']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'type': type,
      'title': title,
      'description': description,
      'status': status,
      'playbackState': playbackState.toJson(),
      'stats': stats.toJson(),
      'metadata': metadata.toJson(),
      if (youtubeData != null) 'youtubeData': youtubeData!.toJson(),
      if (audioData != null) 'audioData': audioData!.toJson(),
      if (playlistData != null) 'playlistData': playlistData!.toJson(),
    };
  }

  MediaContent copyWith({
    String? contentId,
    String? type,
    String? title,
    String? description,
    String? status,
    PlaybackState? playbackState,
    MediaStats? stats,
    MediaMetadata? metadata,
    YouTubeData? youtubeData,
    AudioData? audioData,
    PlaylistData? playlistData,
  }) {
    return MediaContent(
      contentId: contentId ?? this.contentId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      playbackState: playbackState ?? this.playbackState,
      stats: stats ?? this.stats,
      metadata: metadata ?? this.metadata,
      youtubeData: youtubeData ?? this.youtubeData,
      audioData: audioData ?? this.audioData,
      playlistData: playlistData ?? this.playlistData,
    );
  }
}

/// حالة التشغيل
class PlaybackState {
  final bool isPlaying;
  final double currentPosition;
  final double playbackSpeed;
  final double volume;
  final DateTime lastUpdated;

  PlaybackState({
    required this.isPlaying,
    required this.currentPosition,
    required this.playbackSpeed,
    required this.volume,
    required this.lastUpdated,
  });

  factory PlaybackState.fromJson(Map<String, dynamic> json) {
    return PlaybackState(
      isPlaying: json['isPlaying'] ?? false,
      currentPosition: (json['currentPosition'] ?? 0).toDouble(),
      playbackSpeed: (json['playbackSpeed'] ?? 1.0).toDouble(),
      volume: (json['volume'] ?? 100).toDouble(),
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPlaying': isPlaying,
      'currentPosition': currentPosition,
      'playbackSpeed': playbackSpeed,
      'volume': volume,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  PlaybackState copyWith({
    bool? isPlaying,
    double? currentPosition,
    double? playbackSpeed,
    double? volume,
    DateTime? lastUpdated,
  }) {
    return PlaybackState(
      isPlaying: isPlaying ?? this.isPlaying,
      currentPosition: currentPosition ?? this.currentPosition,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      volume: volume ?? this.volume,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// إحصائيات الوسائط
class MediaStats {
  final int playCount;
  final int likeCount;
  final int skipCount;
  final double totalPlayTime;

  MediaStats({
    required this.playCount,
    required this.likeCount,
    required this.skipCount,
    required this.totalPlayTime,
  });

  factory MediaStats.fromJson(Map<String, dynamic> json) {
    return MediaStats(
      playCount: json['playCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
      skipCount: json['skipCount'] ?? 0,
      totalPlayTime: (json['totalPlayTime'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playCount': playCount,
      'likeCount': likeCount,
      'skipCount': skipCount,
      'totalPlayTime': totalPlayTime,
    };
  }
}

/// بيانات وصفية للوسائط
class MediaMetadata {
  final String addedBy;
  final DateTime addedAt;
  final List<String> tags;
  final Map<String, dynamic> permissions;

  MediaMetadata({
    required this.addedBy,
    required this.addedAt,
    required this.tags,
    required this.permissions,
  });

  factory MediaMetadata.fromJson(Map<String, dynamic> json) {
    return MediaMetadata(
      addedBy: json['addedBy'] ?? '',
      addedAt: json['addedAt'] != null 
          ? DateTime.parse(json['addedAt']) 
          : DateTime.now(),
      tags: List<String>.from(json['tags'] ?? []),
      permissions: Map<String, dynamic>.from(json['permissions'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'addedBy': addedBy,
      'addedAt': addedAt.toIso8601String(),
      'tags': tags,
      'permissions': permissions,
    };
  }
}

/// بيانات YouTube
class YouTubeData {
  final String videoId;
  final String title;
  final String description;
  final String thumbnail;
  final int duration;
  final String channelName;
  final int viewCount;

  YouTubeData({
    required this.videoId,
    required this.title,
    required this.description,
    required this.thumbnail,
    required this.duration,
    required this.channelName,
    required this.viewCount,
  });

  factory YouTubeData.fromJson(Map<String, dynamic> json) {
    return YouTubeData(
      videoId: json['videoId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
      duration: json['duration'] ?? 0,
      channelName: json['channelName'] ?? '',
      viewCount: json['viewCount'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoId': videoId,
      'title': title,
      'description': description,
      'thumbnail': thumbnail,
      'duration': duration,
      'channelName': channelName,
      'viewCount': viewCount,
    };
  }
}

/// بيانات الملف الصوتي
class AudioData {
  final String fileName;
  final String fileUrl;
  final int fileSize;
  final int duration;
  final String format;
  final int bitrate;

  AudioData({
    required this.fileName,
    required this.fileUrl,
    required this.fileSize,
    required this.duration,
    required this.format,
    required this.bitrate,
  });

  factory AudioData.fromJson(Map<String, dynamic> json) {
    return AudioData(
      fileName: json['fileName'] ?? '',
      fileUrl: json['fileUrl'] ?? '',
      fileSize: json['fileSize'] ?? 0,
      duration: json['duration'] ?? 0,
      format: json['format'] ?? '',
      bitrate: json['bitrate'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fileName': fileName,
      'fileUrl': fileUrl,
      'fileSize': fileSize,
      'duration': duration,
      'format': format,
      'bitrate': bitrate,
    };
  }
}

/// بيانات قائمة التشغيل
class PlaylistData {
  final String playlistId;
  final String name;
  final String description;
  final List<String> contentIds;
  final int currentIndex;
  final bool shuffle;
  final bool repeat;

  PlaylistData({
    required this.playlistId,
    required this.name,
    required this.description,
    required this.contentIds,
    required this.currentIndex,
    required this.shuffle,
    required this.repeat,
  });

  factory PlaylistData.fromJson(Map<String, dynamic> json) {
    return PlaylistData(
      playlistId: json['playlistId'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      contentIds: List<String>.from(json['contentIds'] ?? []),
      currentIndex: json['currentIndex'] ?? 0,
      shuffle: json['shuffle'] ?? false,
      repeat: json['repeat'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playlistId': playlistId,
      'name': name,
      'description': description,
      'contentIds': contentIds,
      'currentIndex': currentIndex,
      'shuffle': shuffle,
      'repeat': repeat,
    };
  }
}

/// نموذج طلب إضافة محتوى
class AddContentRequest {
  final String roomId;
  final String type;
  final Map<String, dynamic> data;

  AddContentRequest({
    required this.roomId,
    required this.type,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'type': type,
      'data': data,
    };
  }
}

/// نموذج استجابة قائمة المحتوى
class ContentListResponse {
  final List<MediaContent> contents;
  final ContentPagination pagination;

  ContentListResponse({
    required this.contents,
    required this.pagination,
  });

  factory ContentListResponse.fromJson(Map<String, dynamic> json) {
    return ContentListResponse(
      contents: (json['contents'] as List)
          .map((item) => MediaContent.fromJson(item))
          .toList(),
      pagination: ContentPagination.fromJson(json['pagination'] ?? {}),
    );
  }
}

/// معلومات التصفح
class ContentPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  ContentPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory ContentPagination.fromJson(Map<String, dynamic> json) {
    final total = json['total'] ?? 0;
    final limit = json['limit'] ?? 20;
    return ContentPagination(
      page: json['page'] ?? 1,
      limit: limit,
      total: total,
      totalPages: (total / limit).ceil(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'page': page,
      'limit': limit,
      'total': total,
      'totalPages': totalPages,
    };
  }
}

