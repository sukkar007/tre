import 'user_model.dart';

class RoomModel {
  final String id;
  final String roomId;
  final String title;
  final String? description;
  final String category;
  final List<String> tags;
  final UserModel owner;
  final List<MicSeat> seats;
  final int micCount;
  final RoomSettings settings;
  final RoomStats stats;
  final List<UserModel> admins;
  final List<UserModel> bannedUsers;
  final List<WaitingQueueItem> waitingQueue;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final String status;

  RoomModel({
    required this.id,
    required this.roomId,
    required this.title,
    this.description,
    required this.category,
    required this.tags,
    required this.owner,
    required this.seats,
    required this.micCount,
    required this.settings,
    required this.stats,
    required this.admins,
    required this.bannedUsers,
    required this.waitingQueue,
    required this.createdAt,
    required this.lastActiveAt,
    required this.status,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    return RoomModel(
      id: json['_id'] ?? '',
      roomId: json['roomId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      category: json['category'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      owner: UserModel.fromJson(json['owner'] ?? {}),
      seats: (json['seats'] as List?)
          ?.map((seat) => MicSeat.fromJson(seat))
          .toList() ?? [],
      micCount: json['micCount'] ?? 6,
      settings: RoomSettings.fromJson(json['settings'] ?? {}),
      stats: RoomStats.fromJson(json['stats'] ?? {}),
      admins: (json['admins'] as List?)
          ?.map((admin) => UserModel.fromJson(admin))
          .toList() ?? [],
      bannedUsers: (json['bannedUsers'] as List?)
          ?.map((user) => UserModel.fromJson(user))
          .toList() ?? [],
      waitingQueue: (json['waitingQueue'] as List?)
          ?.map((item) => WaitingQueueItem.fromJson(item))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      lastActiveAt: DateTime.parse(json['lastActiveAt'] ?? DateTime.now().toIso8601String()),
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomId': roomId,
      'title': title,
      'description': description,
      'category': category,
      'tags': tags,
      'owner': owner.toJson(),
      'seats': seats.map((seat) => seat.toJson()).toList(),
      'micCount': micCount,
      'settings': settings.toJson(),
      'stats': stats.toJson(),
      'admins': admins.map((admin) => admin.toJson()).toList(),
      'bannedUsers': bannedUsers.map((user) => user.toJson()).toList(),
      'waitingQueue': waitingQueue.map((item) => item.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastActiveAt': lastActiveAt.toIso8601String(),
      'status': status,
    };
  }

  RoomModel copyWith({
    String? id,
    String? roomId,
    String? title,
    String? description,
    String? category,
    List<String>? tags,
    UserModel? owner,
    List<MicSeat>? seats,
    int? micCount,
    RoomSettings? settings,
    RoomStats? stats,
    List<UserModel>? admins,
    List<UserModel>? bannedUsers,
    List<WaitingQueueItem>? waitingQueue,
    DateTime? createdAt,
    DateTime? lastActiveAt,
    String? status,
  }) {
    return RoomModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      owner: owner ?? this.owner,
      seats: seats ?? this.seats,
      micCount: micCount ?? this.micCount,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
      admins: admins ?? this.admins,
      bannedUsers: bannedUsers ?? this.bannedUsers,
      waitingQueue: waitingQueue ?? this.waitingQueue,
      createdAt: createdAt ?? this.createdAt,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      status: status ?? this.status,
    );
  }

  String getUserRole(String userId) {
    if (owner.id == userId) return 'owner';
    if (admins.any((admin) => admin.id == userId)) return 'admin';
    if (seats.any((seat) => seat.userId == userId)) return 'speaker';
    return 'listener';
  }

  bool isUserBanned(String userId) {
    return bannedUsers.any((user) => user.id == userId);
  }

  int getCurrentParticipantCount() {
    return seats.where((seat) => seat.userId != null).length + waitingQueue.length;
  }
}

class MicSeat {
  final int seatNumber;
  final String? userId;
  final UserModel? user;
  final bool isVIP;
  final bool isMuted;
  final bool isLocked;
  final DateTime? joinedAt;

  MicSeat({
    required this.seatNumber,
    this.userId,
    this.user,
    required this.isVIP,
    required this.isMuted,
    required this.isLocked,
    this.joinedAt,
    String? id, // معامل إضافي للتوافق
    int? index, // معامل إضافي للتوافق
    String? userName, // معامل إضافي للتوافق
    String? userAvatar, // معامل إضافي للتوافق
  });

  factory MicSeat.fromJson(Map<String, dynamic> json) {
    return MicSeat(
      seatNumber: json['seatNumber'] ?? 0,
      userId: json['userId'],
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      isVIP: json['isVIP'] ?? false,
      isMuted: json['isMuted'] ?? false,
      isLocked: json['isLocked'] ?? false,
      joinedAt: json['joinedAt'] != null 
          ? DateTime.parse(json['joinedAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'seatNumber': seatNumber,
      'userId': userId,
      'user': user?.toJson(),
      'isVIP': isVIP,
      'isMuted': isMuted,
      'isLocked': isLocked,
      'joinedAt': joinedAt?.toIso8601String(),
    };
  }
}

class RoomSettings {
  final ChatSettings chatSettings;
  final MicSettings micSettings;
  final MediaSettings mediaSettings;
  final AccessSettings accessSettings;

  RoomSettings({
    required this.chatSettings,
    required this.micSettings,
    required this.mediaSettings,
    required this.accessSettings,
  });

  factory RoomSettings.fromJson(Map<String, dynamic> json) {
    return RoomSettings(
      chatSettings: ChatSettings.fromJson(json['chatSettings'] ?? {}),
      micSettings: MicSettings.fromJson(json['micSettings'] ?? {}),
      mediaSettings: MediaSettings.fromJson(json['mediaSettings'] ?? {}),
      accessSettings: AccessSettings.fromJson(json['accessSettings'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'chatSettings': chatSettings.toJson(),
      'micSettings': micSettings.toJson(),
      'mediaSettings': mediaSettings.toJson(),
      'accessSettings': accessSettings.toJson(),
    };
  }
}

class ChatSettings {
  final bool isEnabled;
  final bool profanityFilterEnabled;
  final bool slowModeEnabled;
  final int slowModeInterval;
  final bool adminOnlyMode;

  ChatSettings({
    required this.isEnabled,
    required this.profanityFilterEnabled,
    required this.slowModeEnabled,
    required this.slowModeInterval,
    required this.adminOnlyMode,
  });

  factory ChatSettings.fromJson(Map<String, dynamic> json) {
    return ChatSettings(
      isEnabled: json['isEnabled'] ?? true,
      profanityFilterEnabled: json['profanityFilterEnabled'] ?? true,
      slowModeEnabled: json['slowModeEnabled'] ?? false,
      slowModeInterval: json['slowModeInterval'] ?? 5,
      adminOnlyMode: json['adminOnlyMode'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isEnabled': isEnabled,
      'profanityFilterEnabled': profanityFilterEnabled,
      'slowModeEnabled': slowModeEnabled,
      'slowModeInterval': slowModeInterval,
      'adminOnlyMode': adminOnlyMode,
    };
  }
}

class MicSettings {
  final int totalMics;
  final int vipMics;
  final int guestMics;
  final bool autoMuteNewSpeakers;
  final bool requirePermissionToSpeak;

  MicSettings({
    required this.totalMics,
    required this.vipMics,
    required this.guestMics,
    required this.autoMuteNewSpeakers,
    required this.requirePermissionToSpeak,
  });

  factory MicSettings.fromJson(Map<String, dynamic> json) {
    return MicSettings(
      totalMics: json['totalMics'] ?? 6,
      vipMics: json['vipMics'] ?? 1,
      guestMics: json['guestMics'] ?? 5,
      autoMuteNewSpeakers: json['autoMuteNewSpeakers'] ?? false,
      requirePermissionToSpeak: json['requirePermissionToSpeak'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalMics': totalMics,
      'vipMics': vipMics,
      'guestMics': guestMics,
      'autoMuteNewSpeakers': autoMuteNewSpeakers,
      'requirePermissionToSpeak': requirePermissionToSpeak,
    };
  }
}

class MediaSettings {
  final bool youtubeEnabled;
  final bool musicEnabled;
  final bool soundEffectsEnabled;
  final double masterVolume;
  final double musicVolume;
  final double effectsVolume;

  MediaSettings({
    required this.youtubeEnabled,
    required this.musicEnabled,
    required this.soundEffectsEnabled,
    required this.masterVolume,
    required this.musicVolume,
    required this.effectsVolume,
  });

  factory MediaSettings.fromJson(Map<String, dynamic> json) {
    return MediaSettings(
      youtubeEnabled: json['youtubeEnabled'] ?? false,
      musicEnabled: json['musicEnabled'] ?? false,
      soundEffectsEnabled: json['soundEffectsEnabled'] ?? true,
      masterVolume: (json['masterVolume'] ?? 1.0).toDouble(),
      musicVolume: (json['musicVolume'] ?? 0.7).toDouble(),
      effectsVolume: (json['effectsVolume'] ?? 0.5).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'youtubeEnabled': youtubeEnabled,
      'musicEnabled': musicEnabled,
      'soundEffectsEnabled': soundEffectsEnabled,
      'masterVolume': masterVolume,
      'musicVolume': musicVolume,
      'effectsVolume': effectsVolume,
    };
  }
}

class AccessSettings {
  final bool isPrivate;
  final bool requireApproval;
  final int maxParticipants;
  final List<String> allowedCountries;
  final int minAge;

  AccessSettings({
    required this.isPrivate,
    required this.requireApproval,
    required this.maxParticipants,
    required this.allowedCountries,
    required this.minAge,
  });

  factory AccessSettings.fromJson(Map<String, dynamic> json) {
    return AccessSettings(
      isPrivate: json['isPrivate'] ?? false,
      requireApproval: json['requireApproval'] ?? false,
      maxParticipants: json['maxParticipants'] ?? 100,
      allowedCountries: List<String>.from(json['allowedCountries'] ?? []),
      minAge: json['minAge'] ?? 13,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isPrivate': isPrivate,
      'requireApproval': requireApproval,
      'maxParticipants': maxParticipants,
      'allowedCountries': allowedCountries,
      'minAge': minAge,
    };
  }
}

class RoomStats {
  final int totalJoins;
  final int totalMessages;
  final int peakParticipants;
  final int currentParticipants;
  final Duration totalDuration;
  final Map<String, int> categoryStats;

  RoomStats({
    required this.totalJoins,
    required this.totalMessages,
    required this.peakParticipants,
    required this.currentParticipants,
    required this.totalDuration,
    required this.categoryStats,
  });

  factory RoomStats.fromJson(Map<String, dynamic> json) {
    return RoomStats(
      totalJoins: json['totalJoins'] ?? 0,
      totalMessages: json['totalMessages'] ?? 0,
      peakParticipants: json['peakParticipants'] ?? 0,
      currentParticipants: json['currentParticipants'] ?? 0,
      totalDuration: Duration(seconds: json['totalDuration'] ?? 0),
      categoryStats: Map<String, int>.from(json['categoryStats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalJoins': totalJoins,
      'totalMessages': totalMessages,
      'peakParticipants': peakParticipants,
      'currentParticipants': currentParticipants,
      'totalDuration': totalDuration.inSeconds,
      'categoryStats': categoryStats,
    };
  }
}

class WaitingQueueItem {
  final String userId;
  final UserModel user;
  final DateTime joinedAt;
  final int priority;
  final String? requestedSeat;

  WaitingQueueItem({
    required this.userId,
    required this.user,
    required this.joinedAt,
    required this.priority,
    this.requestedSeat,
  });

  factory WaitingQueueItem.fromJson(Map<String, dynamic> json) {
    return WaitingQueueItem(
      userId: json['userId'] ?? '',
      user: UserModel.fromJson(json['user'] ?? {}),
      joinedAt: DateTime.parse(json['joinedAt'] ?? DateTime.now().toIso8601String()),
      priority: json['priority'] ?? 0,
      requestedSeat: json['requestedSeat'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'user': user.toJson(),
      'joinedAt': joinedAt.toIso8601String(),
      'priority': priority,
      'requestedSeat': requestedSeat,
    };
  }
}

