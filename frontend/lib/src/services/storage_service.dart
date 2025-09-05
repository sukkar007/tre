import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/user_model.dart';

class StorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // مفاتيح التخزين
  static const String _tokenKey = 'app_token';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';
  static const String _deviceIdKey = 'device_id';

  // حفظ توكن التطبيق
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // استرجاع توكن التطبيق
  static Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // حفظ معرّف المستخدم
  static Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  // استرجاع معرّف المستخدم
  static Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  // حفظ بيانات المستخدم (UserModel object)
  static Future<void> saveUserData(UserModel user) async {
    await _storage.write(key: _userDataKey, value: user.toJsonString());
  }

  // حفظ بيانات المستخدم (JSON string)
  static Future<void> saveUserDataAsString(String userData) async {
    await _storage.write(key: _userDataKey, value: userData);
  }

  // استرجاع بيانات المستخدم (String)
  static Future<String?> getUserData() async {
    return await _storage.read(key: _userDataKey);
  }

  // استرجاع بيانات المستخدم (UserModel object)
  static Future<UserModel?> getUserDataAsModel() async {
    final userData = await _storage.read(key: _userDataKey);
    if (userData != null) {
      try {
        return UserModel.fromJsonString(userData);
      } catch (e) {
        print('خطأ في تحويل بيانات المستخدم: $e');
        return null;
      }
    }
    return null;
  }

  // مسح بيانات المستخدم
  static Future<void> clearUserData() async {
    await _storage.delete(key: _userDataKey);
    await _storage.delete(key: _userIdKey);
  }

  // حفظ معرّف الجهاز
  static Future<void> saveDeviceId(String deviceId) async {
    await _storage.write(key: _deviceIdKey, value: deviceId);
  }

  // استرجاع معرّف الجهاز
  static Future<String?> getDeviceId() async {
    return await _storage.read(key: _deviceIdKey);
  }

  // التحقق من وجود توكن صالح
  static Future<bool> hasValidToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // مسح جميع البيانات المحفوظة (تسجيل الخروج)
  static Future<void> clearAll() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _userDataKey);
    // نحتفظ بـ deviceId لأنه مرتبط بالجهاز وليس بالمستخدم
  }

  // مسح توكن فقط (انتهاء الصلاحية)
  static Future<void> clearToken() async {
    await _storage.delete(key: _tokenKey);
  }
}

