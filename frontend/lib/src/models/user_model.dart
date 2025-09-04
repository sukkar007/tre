import 'dart:convert';

class UserModel {
  final String userId;
  final String displayName;
  final String? email;
  final String? photoURL;
  final bool isOnline;
  final DateTime? createdAt;

  UserModel({
    required this.userId,
    required this.displayName,
    this.email,
    this.photoURL,
    this.isOnline = false,
    this.createdAt,
  });

  // تحويل من JSON إلى UserModel
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId'] ?? '',
      displayName: json['displayName'] ?? 'مستخدم',
      email: json['email'],
      photoURL: json['photoURL'],
      isOnline: json['isOnline'] ?? false,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt']) 
          : null,
    );
  }

  // تحويل من UserModel إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'displayName': displayName,
      'email': email,
      'photoURL': photoURL,
      'isOnline': isOnline,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // تحويل إلى JSON string للحفظ في التخزين
  String toJsonString() {
    return jsonEncode(toJson());
  }

  // إنشاء UserModel من JSON string
  factory UserModel.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return UserModel.fromJson(json);
  }

  // إنشاء نسخة محدثة من UserModel
  UserModel copyWith({
    String? userId,
    String? displayName,
    String? email,
    String? photoURL,
    bool? isOnline,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      email: email ?? this.email,
      photoURL: photoURL ?? this.photoURL,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // الحصول على الأحرف الأولى من الاسم (للصورة الافتراضية)
  String get initials {
    final names = displayName.trim().split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return 'U';
  }

  // التحقق من وجود صورة شخصية
  bool get hasProfilePhoto {
    return photoURL != null && 
           photoURL!.isNotEmpty && 
           !photoURL!.contains('placeholder');
  }

  @override
  String toString() {
    return 'UserModel(userId: $userId, displayName: $displayName, email: $email)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.userId == userId;
  }

  @override
  int get hashCode => userId.hashCode;
}

