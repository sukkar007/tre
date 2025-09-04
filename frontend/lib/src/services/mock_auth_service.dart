import 'dart:async';
import 'dart:math';
import '../models/user_model.dart';
import 'storage_service.dart';

/// خدمة المصادقة التجريبية - تعمل بدون Firebase
class MockAuthService {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal();

  final StorageService _storageService = StorageService();
  UserModel? _currentUser;
  final StreamController<UserModel?> _authStateController = StreamController<UserModel?>.broadcast();

  /// تيار حالة المصادقة
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  /// المستخدم الحالي
  UserModel? get currentUser => _currentUser;

  /// قائمة المستخدمين التجريبيين
  final List<Map<String, dynamic>> _demoUsers = [
    {
      'id': 'user_001',
      'name': 'أحمد محمد',
      'email': 'ahmed@demo.com',
      'avatar': 'https://via.placeholder.com/150/FF6B6B/FFFFFF?text=أحمد',
      'level': 15,
      'points': 2500,
      'isVip': true,
    },
    {
      'id': 'user_002', 
      'name': 'فاطمة علي',
      'email': 'fatima@demo.com',
      'avatar': 'https://via.placeholder.com/150/4ECDC4/FFFFFF?text=فاطمة',
      'level': 12,
      'points': 1800,
      'isVip': false,
    },
    {
      'id': 'user_003',
      'name': 'محمد حسن',
      'email': 'mohammed@demo.com', 
      'avatar': 'https://via.placeholder.com/150/45B7D1/FFFFFF?text=محمد',
      'level': 8,
      'points': 950,
      'isVip': false,
    },
    {
      'id': 'user_004',
      'name': 'نور الدين',
      'email': 'nour@demo.com',
      'avatar': 'https://via.placeholder.com/150/F7DC6F/FFFFFF?text=نور',
      'level': 20,
      'points': 4200,
      'isVip': true,
    },
    {
      'id': 'user_005',
      'name': 'سارة أحمد',
      'email': 'sara@demo.com',
      'avatar': 'https://via.placeholder.com/150/BB8FCE/FFFFFF?text=سارة',
      'level': 6,
      'points': 720,
      'isVip': false,
    },
  ];

  /// تسجيل الدخول التجريبي
  Future<UserModel?> signInDemo({String? userId}) async {
    try {
      // محاكاة تأخير الشبكة
      await Future.delayed(const Duration(seconds: 2));

      // اختيار مستخدم عشوائي أو محدد
      final userData = userId != null 
          ? _demoUsers.firstWhere((user) => user['id'] == userId, orElse: () => _demoUsers.first)
          : _demoUsers[Random().nextInt(_demoUsers.length)];

      _currentUser = UserModel.fromJson(userData);
      
      // حفظ بيانات المستخدم محلياً
      await _storageService.saveUserData(_currentUser!);
      
      // إشعار المستمعين
      _authStateController.add(_currentUser);
      
      return _currentUser;
    } catch (e) {
      print('خطأ في تسجيل الدخول التجريبي: $e');
      return null;
    }
  }

  /// تسجيل الدخول بـ Google (تجريبي)
  Future<UserModel?> signInWithGoogle() async {
    return await signInDemo();
  }

  /// تسجيل الدخول برقم الهاتف (تجريبي)
  Future<UserModel?> signInWithPhone(String phoneNumber) async {
    // إنشاء مستخدم جديد بناءً على رقم الهاتف
    final newUser = {
      'id': 'phone_${phoneNumber.replaceAll('+', '').replaceAll(' ', '')}',
      'name': 'مستخدم ${phoneNumber.substring(phoneNumber.length - 4)}',
      'email': 'user_${phoneNumber.substring(phoneNumber.length - 4)}@demo.com',
      'avatar': 'https://via.placeholder.com/150/85C1E9/FFFFFF?text=${phoneNumber.substring(phoneNumber.length - 2)}',
      'level': 1,
      'points': 0,
      'isVip': false,
      'phoneNumber': phoneNumber,
    };

    _currentUser = UserModel.fromJson(newUser);
    await _storageService.saveUserData(_currentUser!);
    _authStateController.add(_currentUser);
    
    return _currentUser;
  }

  /// استعادة جلسة المستخدم
  Future<UserModel?> restoreSession() async {
    try {
      final userData = await _storageService.getUserData();
      if (userData != null) {
        _currentUser = userData;
        _authStateController.add(_currentUser);
        return _currentUser;
      }
    } catch (e) {
      print('خطأ في استعادة الجلسة: $e');
    }
    return null;
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    _currentUser = null;
    await _storageService.clearUserData();
    _authStateController.add(null);
  }

  /// تحديث بيانات المستخدم
  Future<UserModel?> updateUserProfile({
    String? name,
    String? avatar,
  }) async {
    if (_currentUser == null) return null;

    try {
      // محاكاة تأخير الشبكة
      await Future.delayed(const Duration(milliseconds: 500));

      _currentUser = _currentUser!.copyWith(
        name: name ?? _currentUser!.name,
        avatar: avatar ?? _currentUser!.avatar,
      );

      await _storageService.saveUserData(_currentUser!);
      _authStateController.add(_currentUser);
      
      return _currentUser;
    } catch (e) {
      print('خطأ في تحديث الملف الشخصي: $e');
      return null;
    }
  }

  /// الحصول على مستخدم تجريبي بالمعرف
  UserModel? getDemoUser(String userId) {
    try {
      final userData = _demoUsers.firstWhere((user) => user['id'] == userId);
      return UserModel.fromJson(userData);
    } catch (e) {
      return null;
    }
  }

  /// الحصول على قائمة المستخدمين التجريبيين
  List<UserModel> getAllDemoUsers() {
    return _demoUsers.map((userData) => UserModel.fromJson(userData)).toList();
  }

  /// محاكاة التحقق من رقم الهاتف
  Future<bool> verifyPhoneNumber(String phoneNumber, String verificationCode) async {
    // محاكاة تأخير التحقق
    await Future.delayed(const Duration(seconds: 1));
    
    // قبول أي رمز تحقق يحتوي على "123"
    return verificationCode.contains('123');
  }

  /// إنشاء رمز تحقق وهمي
  String generateDemoVerificationCode() {
    return '123456';
  }

  /// التحقق من حالة المصادقة
  bool get isAuthenticated => _currentUser != null;

  /// تنظيف الموارد
  void dispose() {
    _authStateController.close();
  }
}

/// إضافة copyWith للـ UserModel
extension UserModelCopyWith on UserModel {
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? avatar,
    int? level,
    int? points,
    bool? isVip,
    String? phoneNumber,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      level: level ?? this.level,
      points: points ?? this.points,
      isVip: isVip ?? this.isVip,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

