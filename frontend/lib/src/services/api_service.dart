import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/splash_model.dart';

class ApiService {
  // عنوان الخادم المحلي.
  // بالنسبة لمُحاكي أندرويد، لا يمكن استخدام localhost مباشرة،
  // بل يجب استخدام العنوان الخاص 10.0.2.2 الذي يشير إلى localhost الخاص بالكمبيوتر.
  static const String _baseUrl = 'http://10.0.2.2:3000/api';

  // الحصول على محتوى شاشة Splash
  Future<SplashResponse?> getSplashContent({
    String platform = 'android',
    String? country,
    String? language,
    String? version,
  }) async {
    final queryParams = <String, String>{
      'platform': platform,
    };
    
    if (country != null) queryParams['country'] = country;
    if (language != null) queryParams['language'] = language;
    if (version != null) queryParams['version'] = version;

    final uri = Uri.parse('$_baseUrl/splash/content').replace(queryParameters: queryParams);

    try {
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        print("تم استلام محتوى شاشة Splash: ${responseBody['content']['title']}");
        return SplashResponse.fromJson(responseBody);
      } else {
        print("فشل في الحصول على محتوى شاشة Splash: ${response.statusCode}");
        print("رسالة الخطأ: ${response.body}");
        return null;
      }
    } catch (e) {
      print("خطأ في الاتصال بالخادم للحصول على محتوى Splash: $e");
      return null;
    }
  }

  // تسجيل نقرة على إعلان
  Future<bool> recordAdClick(String contentId, String adId) async {
    final url = Uri.parse('$_baseUrl/splash/ad-click');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode({
          'contentId': contentId,
          'adId': adId,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return responseBody['success'] == true;
      } else {
        print("فشل في تسجيل نقرة الإعلان: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("خطأ في تسجيل نقرة الإعلان: $e");
      return false;
    }
  }

  // دالة لإرسال طلب تسجيل الدخول إلى الخادم
  Future<Map<String, dynamic>?> loginOrRegister(String idToken, String deviceId) async {
    final url = Uri.parse('$_baseUrl/auth/login');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, String>{
          'idToken': idToken,
          'deviceId': deviceId,
        }),
      );

      if (response.statusCode == 200) {
        // نجح الطلب
        final responseBody = jsonDecode(response.body);
        print("تم استلام رد ناجح من الخادم: $responseBody");
        return responseBody;
      } else {
        // فشل الطلب
        print("فشل الطلب للخادم: ${response.statusCode}");
        print("رسالة الخطأ من الخادم: ${response.body}");
        return null;
      }
    } catch (e) {
      // حدث خطأ أثناء محاولة الاتصال بالخادم
      print("خطأ في الاتصال بالخادم: $e");
      return null;
    }
  }

  // التحقق من صحة التوكن
  Future<Map<String, dynamic>?> verifyToken(String token) async {
    final url = Uri.parse('$_baseUrl/auth/verify');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json; charset=UTF-8',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        return responseBody;
      } else {
        print("فشل في التحقق من التوكن: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      print("خطأ في التحقق من التوكن: $e");
      return null;
    }
  }
}

