class RoomMessageModel {
  final String id;
  final String roomId;
  final String senderId;
  final String senderName;
  final String? senderProfilePicture;
  final String senderRole;
  final String content;
  final String messageType;
  final RoomMessageModel? replyTo;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final DateTime? editedAt;
  final bool isDeleted;
  final List<String> reactions;

  RoomMessageModel({
    required this.id,
    required this.roomId,
    required this.senderId,
    String? userId, // معامل إضافي للتوافق
    required this.senderName,
    String? userName, // معامل إضافي للتوافق
    this.senderProfilePicture,
    String? userAvatar, // معامل إضافي للتوافق
    required this.senderRole,
    required this.content,
    required this.messageType,
    this.replyTo,
    this.metadata,
    required this.createdAt,
    this.editedAt,
    required this.isDeleted,
    required this.reactions,
  });

  factory RoomMessageModel.fromJson(Map<String, dynamic> json) {
    return RoomMessageModel(
      id: json['_id'] ?? '',
      roomId: json['roomId'] ?? '',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderProfilePicture: json['senderProfilePicture'],
      senderRole: json['senderRole'] ?? 'listener',
      content: json['content'] ?? '',
      messageType: json['messageType'] ?? 'text',
      replyTo: json['replyTo'] != null 
          ? RoomMessageModel.fromJson(json['replyTo']) 
          : null,
      metadata: json['metadata'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      editedAt: json['editedAt'] != null 
          ? DateTime.parse(json['editedAt']) 
          : null,
      isDeleted: json['isDeleted'] ?? false,
      reactions: List<String>.from(json['reactions'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'roomId': roomId,
      'senderId': senderId,
      'senderName': senderName,
      'senderProfilePicture': senderProfilePicture,
      'senderRole': senderRole,
      'content': content,
      'messageType': messageType,
      'replyTo': replyTo?.toJson(),
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'isDeleted': isDeleted,
      'reactions': reactions,
    };
  }

  // إنشاء رسالة نظام
  factory RoomMessageModel.createSystemMessage({
    required String roomId,
    required String content,
    required String messageType,
    String? userId,
    String? userName,
    String? userProfilePicture,
    Map<String, dynamic>? metadata,
  }) {
    return RoomMessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      roomId: roomId,
      senderId: userId ?? 'system',
      senderName: userName ?? 'النظام',
      senderProfilePicture: userProfilePicture,
      senderRole: 'system',
      content: content,
      messageType: messageType,
      metadata: metadata,
      createdAt: DateTime.now(),
      isDeleted: false,
      reactions: [],
    );
  }

  // إنشاء رسالة انضمام
  factory RoomMessageModel.createJoinMessage({
    required String roomId,
    required String userId,
    required String userName,
    String? userProfilePicture,
  }) {
    return RoomMessageModel.createSystemMessage(
      roomId: roomId,
      content: 'انضم إلى الغرفة',
      messageType: 'user_joined',
      userId: userId,
      userName: userName,
      userProfilePicture: userProfilePicture,
    );
  }

  // إنشاء رسالة مغادرة
  factory RoomMessageModel.createLeaveMessage({
    required String roomId,
    required String userId,
    required String userName,
    String? userProfilePicture,
  }) {
    return RoomMessageModel.createSystemMessage(
      roomId: roomId,
      content: 'غادر الغرفة',
      messageType: 'user_left',
      userId: userId,
      userName: userName,
      userProfilePicture: userProfilePicture,
    );
  }

  // إنشاء رسالة تغيير المايك
  factory RoomMessageModel.createMicChangeMessage({
    required String roomId,
    required String userId,
    required String userName,
    String? userProfilePicture,
    required String action,
    int? seatNumber,
  }) {
    String content;
    switch (action) {
      case 'joined_mic':
        content = seatNumber != null 
            ? 'انتقل إلى المايك $seatNumber'
            : 'انتقل إلى المايك';
        break;
      case 'left_mic':
        content = 'غادر المايك';
        break;
      case 'muted':
        content = 'تم كتم المايك';
        break;
      case 'unmuted':
        content = 'تم إلغاء كتم المايك';
        break;
      default:
        content = 'تغيير في المايك';
    }

    return RoomMessageModel.createSystemMessage(
      roomId: roomId,
      content: content,
      messageType: 'mic_change',
      userId: userId,
      userName: userName,
      userProfilePicture: userProfilePicture,
      metadata: {
        'action': action,
        'seatNumber': seatNumber,
      },
    );
  }

  // إنشاء رسالة إجراء إداري
  factory RoomMessageModel.createAdminActionMessage({
    required String roomId,
    required String adminId,
    required String adminName,
    String? adminProfilePicture,
    required String targetUserId,
    required String targetUserName,
    required String action,
  }) {
    String content;
    switch (action) {
      case 'kicked':
        content = 'تم طرد $targetUserName من الغرفة';
        break;
      case 'banned':
        content = 'تم حظر $targetUserName';
        break;
      case 'assigned_admin':
        content = 'تم تعيين $targetUserName كمدير';
        break;
      case 'removed_admin':
        content = 'تم إزالة $targetUserName من الإدارة';
        break;
      default:
        content = 'إجراء إداري على $targetUserName';
    }

    return RoomMessageModel.createSystemMessage(
      roomId: roomId,
      content: content,
      messageType: 'admin_action',
      userId: adminId,
      userName: adminName,
      userProfilePicture: adminProfilePicture,
      metadata: {
        'action': action,
        'targetUserId': targetUserId,
        'targetUserName': targetUserName,
      },
    );
  }

  // نسخ الرسالة مع تعديلات
  RoomMessageModel copyWith({
    String? id,
    String? roomId,
    String? senderId,
    String? senderName,
    String? senderProfilePicture,
    String? senderRole,
    String? content,
    String? messageType,
    RoomMessageModel? replyTo,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? editedAt,
    bool? isDeleted,
    List<String>? reactions,
  }) {
    return RoomMessageModel(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderProfilePicture: senderProfilePicture ?? this.senderProfilePicture,
      senderRole: senderRole ?? this.senderRole,
      content: content ?? this.content,
      messageType: messageType ?? this.messageType,
      replyTo: replyTo ?? this.replyTo,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      editedAt: editedAt ?? this.editedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      reactions: reactions ?? this.reactions,
    );
  }

  // التحقق من نوع الرسالة
  bool get isSystemMessage => messageType == 'system' || 
                             messageType == 'user_joined' || 
                             messageType == 'user_left' || 
                             messageType == 'mic_change' || 
                             messageType == 'admin_action';

  bool get isUserMessage => messageType == 'text' || 
                           messageType == 'image' || 
                           messageType == 'audio' || 
                           messageType == 'emoji';

  bool get hasReply => replyTo != null;

  bool get isEdited => editedAt != null;

  bool get hasReactions => reactions.isNotEmpty;
}

