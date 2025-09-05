import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'dart:convert';

import '../models/user_model.dart';
import 'storage_service.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final ApiService _apiService = ApiService();

  // حالة المصادقة
  UserModel? _currentUser;
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _errorMessage;

  // Getters
  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  bool get isLoggedIn => _currentUser != null;
  String? get errorMessage => _errorMessage;

  // تهيئة الخدمة عند بدء التطبيق
  Future<void> initialize() async {
    if (_isInitialized) return;

    _setLoading(true);
    try {
      // التحقق من وجود توكن محفوظ
      final hasToken = await StorageService.hasValidToken();
      if (hasToken) {
        // محاولة استرجاع بيانات المستخدم المحفوظة
        await _loadUserFromStorage();
        
        // التحقق من صحة التوكن مع الخادم
        final isValid = await _verifyTokenWithServer();
        if (!isValid) {
          // التوكن غير صالح، مسح البيانات
          await signOut();
        }
      }
    } catch (e) {
      print('خطأ في تهيئة AuthService: $e');
      await signOut(); // مسح أي بيانات فاسدة
    } finally {
      _isInitialized = true;
      _setLoading(false);
    }
  }

  // تحميل بيانات المستخدم من التخزين المحلي
  Future<void> _loadUserFromStorage() async {
    try {
      final userData = await StorageService.getUserDataAsModel();
      if (userData != null) {
        _currentUser = userData;
        notifyListeners();
      }
    } catch (e) {
      print('خطأ في تحميل بيانات المستخدم: $e');
    }
  }

  // التحقق من صحة التوكن مع الخادم
  Future<bool> _verifyTokenWithServer() async {
    try {
      final token = await StorageService.getToken();
      if (token == null) return false;

      final response = await _apiService.verifyToken(token);
      return response != null && response['success'] == true;
    } catch (e) {
      print('خطأ في التحقق من التوكن: $e');
      return false;
    }
  }

  // الحصول على معرّف الجهاز
  Future<String?> getDeviceId() async {
    try {
      // محاولة استرجاع معرّف محفوظ أولاً
      String? deviceId = await StorageService.getDeviceId();
      if (deviceId != null) return deviceId;

      // إنشاء معرّف جديد
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await _deviceInfo.androidInfo;
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await _deviceInfo.iosInfo;
        deviceId = iosInfo.identifierForVendor;
      }

      // حفظ المعرّف للاستخدام المستقبلي
      if (deviceId != null) {
        await StorageService.saveDeviceId(deviceId);
      }

      return deviceId;
    } catch (e) {
      print("فشل الحصول على معرّف الجهاز: $e");
      return null;
    }
  }

  // تسجيل الدخول باستخدام Google
  Future<bool> signInWithGoogle() async {
    _clearError();
    _setLoading(true);

    try {
      // 1. تسجيل الدخول مع Firebase
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _setError('تم إلغاء تسجيل الدخول');
        return false;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      if (userCredential.user == null) {
        _setError('فشل في تسجيل الدخول مع Firebase');
        return false;
      }

      // 2. الحصول على معرّف الجهاز و idToken
      final deviceId = await getDeviceId();
      final idToken = await userCredential.user!.getIdToken();

      if (deviceId == null || idToken == null) {
        _setError('فشل في الحصول على معلومات الجهاز');
        return false;
      }

      // 3. إرسال البيانات إلى الخادم
      final apiResponse = await _apiService.loginOrRegister(idToken, deviceId);
      if (apiResponse == null || apiResponse['success'] != true) {
        _setError('فشل في تسجيل الدخول مع الخادم');
        return false;
      }

      // 4. حفظ البيانات محلياً
      final String appToken = apiResponse['token'];
      final Map<String, dynamic> userData = apiResponse['user'];
      
      _currentUser = UserModel.fromJson(userData);
      
      await StorageService.saveToken(appToken);
      await StorageService.saveUserId(_currentUser!.userId);
      await StorageService.saveUserData(_currentUser!);

      notifyListeners();
      return true;

    } on FirebaseAuthException catch (e) {
      _setError('خطأ في المصادقة: ${e.message}');
      return false;
    } catch (e) {
      _setError('حدث خطأ غير متوقع: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // تسجيل الخروج
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _googleSignIn.signOut();
      await _firebaseAuth.signOut();
      await StorageService.clearAll();
      
      _currentUser = null;
      notifyListeners();
    } catch (e) {
      print('خطأ في تسجيل الخروج: $e');
    } finally {
      _setLoading(false);
    }
  }

  // تحديث بيانات المستخدم
  Future<void> updateUserProfile({
    String? displayName,
    String? email,
    String? photoURL,
    bool? isVip,
  }) async {
    if (_currentUser == null) return;

    _currentUser = _currentUser!.copyWith(
      displayName: displayName ?? _currentUser!.displayName,
      email: email ?? _currentUser!.email,
      photoURL: photoURL ?? _currentUser!.photoURL,
      isVip: isVip ?? _currentUser!.isVip,
    );

    await StorageService.saveUserData(_currentUser!);
    notifyListeners();
  }

  // تحديث بيانات المستخدم
  Future<void> updateUserData(UserModel updatedUser) async {
    _currentUser = updatedUser;
    await StorageService.saveUserData(updatedUser);
    notifyListeners();
  }

  // دوال مساعدة لإدارة الحالة
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // مسح رسالة الخطأ
  void clearError() {
    _clearError();
  }
}

