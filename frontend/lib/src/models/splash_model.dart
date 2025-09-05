import 'dart:convert';

class SplashContentModel {
  final String contentId;
  final String title;
  final String? subtitle;
  final String? description;
  final String? backgroundImage;
  final String? logoImage;
  final SplashColors colors;
  final SplashSettings settings;
  final List<Advertisement> advertisements;

  SplashContentModel({
    required this.contentId,
    required this.title,
    this.subtitle,
    this.description,
    this.backgroundImage,
    this.logoImage,
    required this.colors,
    required this.settings,
    this.advertisements = const [],
  });

  factory SplashContentModel.fromJson(Map<String, dynamic> json) {
    return SplashContentModel(
      contentId: json['contentId'] ?? 'default',
      title: json['title'] ?? 'مرحباً بك',
      subtitle: json['subtitle'],
      description: json['description'],
      backgroundImage: json['backgroundImage'],
      logoImage: json['logoImage'],
      colors: SplashColors.fromJson(json['colors'] ?? {}),
      settings: SplashSettings.fromJson(json['settings'] ?? {}),
      advertisements: (json['advertisements'] as List<dynamic>?)
          ?.map((ad) => Advertisement.fromJson(ad))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'contentId': contentId,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'backgroundImage': backgroundImage,
      'logoImage': logoImage,
      'colors': colors.toJson(),
      'settings': settings.toJson(),
      'advertisements': advertisements.map((ad) => ad.toJson()).toList(),
    };
  }
}

class SplashColors {
  final String primary;
  final String secondary;
  final String text;
  final String background;

  SplashColors({
    required this.primary,
    required this.secondary,
    required this.text,
    required this.background,
  });

  factory SplashColors.fromJson(Map<String, dynamic> json) {
    return SplashColors(
      primary: json['primary'] ?? '#6366f1',
      secondary: json['secondary'] ?? '#8b5cf6',
      text: json['text'] ?? '#ffffff',
      background: json['background'] ?? '#1f2937',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'primary': primary,
      'secondary': secondary,
      'text': text,
      'background': background,
    };
  }
}

class SplashSettings {
  final int displayDuration;
  final bool showProgressBar;
  final String animationType;

  SplashSettings({
    required this.displayDuration,
    required this.showProgressBar,
    required this.animationType,
  });

  factory SplashSettings.fromJson(Map<String, dynamic> json) {
    return SplashSettings(
      displayDuration: json['displayDuration'] ?? 3000,
      showProgressBar: json['showProgressBar'] ?? true,
      animationType: json['animationType'] ?? 'fade',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'displayDuration': displayDuration,
      'showProgressBar': showProgressBar,
      'animationType': animationType,
    };
  }
}

class Advertisement {
  final String adId;
  final String title;
  final String? description;
  final String? imageUrl;
  final String? actionUrl;
  final int displayOrder;
  final bool isActive;

  Advertisement({
    required this.adId,
    required this.title,
    this.description,
    this.imageUrl,
    this.actionUrl,
    this.displayOrder = 0,
    this.isActive = true,
  });

  factory Advertisement.fromJson(Map<String, dynamic> json) {
    return Advertisement(
      adId: json['adId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      imageUrl: json['imageUrl'],
      actionUrl: json['actionUrl'],
      displayOrder: json['displayOrder'] ?? 0,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'adId': adId,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'actionUrl': actionUrl,
      'displayOrder': displayOrder,
      'isActive': isActive,
    };
  }
}

class SplashResponse {
  final bool success;
  final SplashContentModel? content;
  final String? message;
  final DateTime timestamp;

  SplashResponse({
    required this.success,
    this.content,
    this.message,
    required this.timestamp,
  });

  factory SplashResponse.fromJson(Map<String, dynamic> json) {
    return SplashResponse(
      success: json['success'] ?? false,
      content: json['content'] != null 
          ? SplashContentModel.fromJson(json['content'])
          : null,
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'content': content?.toJson(),
      'message': message,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

