import 'dart:async';
import 'dart:math';
import '../models/user_model.dart';
import 'storage_service.dart';

/// خدمة المصادقة التجريبية - تعمل بدون Firebase
class MockAuthService {
  static final MockAuthService _instance = MockAuthService._internal();
  factory MockAuthService() => _instance;
  MockAuthService._internal();

  UserModel? _currentUser;
  final StreamController<UserModel?> _authStateController = StreamController<UserModel?>.broadcast();

  /// تيار حالة المصادقة
  Stream<UserModel?> get authStateChanges => _authStateController.stream;

  /// المستخدم الحالي
  UserModel? get currentUser => _currentUser;

  /// قائمة المستخدمين التجريبيين
  final List<Map<String, dynamic>> _demoUsers = [
    {
      'userId': 'user_001',
      'displayName': 'أحمد محمد',
      'email': 'ahmed@demo.com',
      'photoURL': 'https://via.placeholder.com/150/FF6B6B/FFFFFF?text=أحمد',
      'isOnline': true,
      'isVip': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
    },
    {
      'userId': 'user_002', 
      'displayName': 'فاطمة علي',
      'email': 'fatima@demo.com',
      'photoURL': 'https://via.placeholder.com/150/4ECDC4/FFFFFF?text=فاطمة',
      'isOnline': true,
      'isVip': false,
      'createdAt': DateTime.now().subtract(const Duration(days: 25)).toIso8601String(),
    },
    {
      'userId': 'user_003',
      'displayName': 'محمد حسن',
      'email': 'mohammed@demo.com', 
      'photoURL': 'https://via.placeholder.com/150/45B7D1/FFFFFF?text=محمد',
      'isOnline': false,
      'isVip': false,
      'createdAt': DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
    },
    {
      'userId': 'user_004',
      'displayName': 'نور الدين',
      'email': 'nour@demo.com',
      'photoURL': 'https://via.placeholder.com/150/F7DC6F/FFFFFF?text=نور',
      'isOnline': true,
      'isVip': true,
      'createdAt': DateTime.now().subtract(const Duration(days: 15)).toIso8601String(),
    },
    {
      'userId': 'user_005',
      'displayName': 'سارة أحمد',
      'email': 'sara@demo.com',
      'photoURL': 'https://via.placeholder.com/150/BB8FCE/FFFFFF?text=سارة',
      'isOnline': true,
      'isVip': false,
      'createdAt': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
    },
  ];

  /// تسجيل الدخول التجريبي
  Future<UserModel?> signInDemo({String? userId}) async {
    try {
      // محاكاة تأخير الشبكة
      await Future.delayed(const Duration(seconds: 2));

      // اختيار مستخدم عشوائي أو محدد
      final userData = userId != null 
          ? _demoUsers.firstWhere((user) => user['userId'] == userId, orElse: () => _demoUsers.first)
          : _demoUsers[Random().nextInt(_demoUsers.length)];

      _currentUser = UserModel.fromJson(userData);
      
      // حفظ بيانات المستخدم محلياً
      await StorageService.saveUserData(_currentUser!);
      
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
      'userId': 'phone_${phoneNumber.replaceAll('+', '').replaceAll(' ', '')}',
      'displayName': 'مستخدم ${phoneNumber.substring(phoneNumber.length - 4)}',
      'email': 'user_${phoneNumber.substring(phoneNumber.length - 4)}@demo.com',
      'photoURL': 'https://via.placeholder.com/150/85C1E9/FFFFFF?text=${phoneNumber.substring(phoneNumber.length - 2)}',
      'isOnline': true,
      'isVip': false,
      'createdAt': DateTime.now().toIso8601String(),
    };

    _currentUser = UserModel.fromJson(newUser);
    await StorageService.saveUserData(_currentUser!);
    _authStateController.add(_currentUser);
    
    return _currentUser;
  }

  /// استعادة جلسة المستخدم
  Future<UserModel?> restoreSession() async {
    try {
      final userData = await StorageService.getUserDataAsModel();
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
    await StorageService.clearUserData();
    _authStateController.add(null);
  }

  /// تحديث بيانات المستخدم
  Future<UserModel?> updateUserProfile({
    String? displayName,
    String? photoURL,
    bool? isVip,
  }) async {
    if (_currentUser == null) return null;

    try {
      // محاكاة تأخير الشبكة
      await Future.delayed(const Duration(milliseconds: 500));

      _currentUser = _currentUser!.copyWith(
        displayName: displayName ?? _currentUser!.displayName,
        photoURL: photoURL ?? _currentUser!.photoURL,
        isVip: isVip ?? _currentUser!.isVip,
      );

      await StorageService.saveUserData(_currentUser!);
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
      final userData = _demoUsers.firstWhere((user) => user['userId'] == userId);
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

