import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'app_constants.dart';

class ErrorHandler {
  // معالجة أخطاء الشبكة
  static String handleNetworkError(dynamic error) {
    if (error is SocketException) {
      return AppConstants.networkErrorMessage;
    } else if (error is HttpException) {
      return 'خطأ في الاتصال بالخادم (${error.message})';
    } else if (error is FormatException) {
      return 'خطأ في تنسيق البيانات المستلمة';
    }
    return AppConstants.unknownErrorMessage;
  }

  // معالجة أخطاء Firebase Auth
  static String handleAuthError(FirebaseAuthException error) {
    switch (error.code) {
      case 'user-not-found':
        return 'لم يتم العثور على حساب بهذا البريد الإلكتروني';
      case 'wrong-password':
        return 'كلمة المرور غير صحيحة';
      case 'email-already-in-use':
        return 'هذا البريد الإلكتروني مستخدم بالفعل';
      case 'weak-password':
        return 'كلمة المرور ضعيفة جداً';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صالح';
      case 'user-disabled':
        return 'تم تعطيل هذا الحساب';
      case 'too-many-requests':
        return 'تم تجاوز عدد المحاولات المسموح، حاول لاحقاً';
      case 'operation-not-allowed':
        return 'هذه العملية غير مسموحة';
      case 'account-exists-with-different-credential':
        return 'يوجد حساب بنفس البريد الإلكتروني بطريقة تسجيل دخول مختلفة';
      case 'invalid-credential':
        return 'بيانات الاعتماد غير صالحة';
      case 'credential-already-in-use':
        return 'بيانات الاعتماد مستخدمة بالفعل مع حساب آخر';
      case 'invalid-verification-code':
        return 'رمز التحقق غير صحيح';
      case 'invalid-verification-id':
        return 'معرف التحقق غير صالح';
      case 'session-expired':
        return 'انتهت صلاحية الجلسة، يرجى المحاولة مرة أخرى';
      case 'quota-exceeded':
        return 'تم تجاوز الحد المسموح، حاول لاحقاً';
      case 'app-not-authorized':
        return 'التطبيق غير مخول لاستخدام Firebase Auth';
      case 'keychain-error':
        return 'خطأ في سلسلة المفاتيح';
      case 'internal-error':
        return 'خطأ داخلي، يرجى المحاولة لاحقاً';
      case 'network-request-failed':
        return AppConstants.networkErrorMessage;
      default:
        return 'خطأ في المصادقة: ${error.message ?? AppConstants.authErrorMessage}';
    }
  }

  // معالجة أخطاء HTTP
  static String handleHttpError(int statusCode, String? message) {
    switch (statusCode) {
      case 400:
        return 'طلب غير صالح: ${message ?? 'البيانات المرسلة غير صحيحة'}';
      case 401:
        return 'غير مخول: ${message ?? 'يرجى تسجيل الدخول مرة أخرى'}';
      case 403:
        return 'ممنوع: ${message ?? 'ليس لديك صلاحية للوصول'}';
      case 404:
        return 'غير موجود: ${message ?? 'المورد المطلوب غير موجود'}';
      case 408:
        return 'انتهت مهلة الطلب: ${message ?? 'الطلب استغرق وقتاً أطول من المتوقع'}';
      case 409:
        return 'تعارض: ${message ?? 'البيانات متعارضة مع البيانات الموجودة'}';
      case 422:
        return 'بيانات غير قابلة للمعالجة: ${message ?? 'البيانات المرسلة غير صالحة'}';
      case 429:
        return 'تم تجاوز الحد المسموح: ${message ?? 'حاول مرة أخرى لاحقاً'}';
      case 500:
        return 'خطأ في الخادم: ${message ?? AppConstants.serverErrorMessage}';
      case 502:
        return 'بوابة سيئة: ${message ?? 'خطأ في الاتصال بالخادم'}';
      case 503:
        return 'الخدمة غير متاحة: ${message ?? 'الخادم غير متاح حالياً'}';
      case 504:
        return 'انتهت مهلة البوابة: ${message ?? 'الخادم لا يستجيب'}';
      default:
        return 'خطأ HTTP ($statusCode): ${message ?? AppConstants.serverErrorMessage}';
    }
  }

  // معالجة أخطاء التحقق من صحة البيانات
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) {
      return 'البريد الإلكتروني مطلوب';
    }
    
    final emailRegex = RegExp(AppConstants.emailPattern);
    if (!emailRegex.hasMatch(email)) {
      return 'البريد الإلكتروني غير صالح';
    }
    
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) {
      return 'كلمة المرور مطلوبة';
    }
    
    if (password.length < 6) {
      return 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
    }
    
    if (!password.contains(RegExp(r'[A-Za-z]'))) {
      return 'كلمة المرور يجب أن تحتوي على حرف واحد على الأقل';
    }
    
    if (!password.contains(RegExp(r'[0-9]'))) {
      return 'كلمة المرور يجب أن تحتوي على رقم واحد على الأقل';
    }
    
    return null;
  }

  static String? validatePhone(String? phone) {
    if (phone == null || phone.isEmpty) {
      return 'رقم الهاتف مطلوب';
    }
    
    final phoneRegex = RegExp(AppConstants.phonePattern);
    if (!phoneRegex.hasMatch(phone)) {
      return 'رقم الهاتف غير صالح';
    }
    
    return null;
  }

  static String? validateUsername(String? username) {
    if (username == null || username.isEmpty) {
      return 'اسم المستخدم مطلوب';
    }
    
    if (username.length < AppConstants.minUsernameLength) {
      return 'اسم المستخدم يجب أن يكون ${AppConstants.minUsernameLength} أحرف على الأقل';
    }
    
    if (username.length > AppConstants.maxUsernameLength) {
      return 'اسم المستخدم يجب أن يكون ${AppConstants.maxUsernameLength} حرف كحد أقصى';
    }
    
    final usernameRegex = RegExp(AppConstants.usernamePattern);
    if (!usernameRegex.hasMatch(username)) {
      return 'اسم المستخدم يجب أن يحتوي على أحرف وأرقام و _ فقط';
    }
    
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName مطلوب';
    }
    return null;
  }

  static String? validateLength(String? value, String fieldName, int minLength, int maxLength) {
    if (value == null) return '$fieldName مطلوب';
    
    if (value.length < minLength) {
      return '$fieldName يجب أن يكون $minLength أحرف على الأقل';
    }
    
    if (value.length > maxLength) {
      return '$fieldName يجب أن يكون $maxLength حرف كحد أقصى';
    }
    
    return null;
  }

  // عرض رسائل الخطأ
  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'إغلاق',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  // عرض رسائل النجاح
  static void showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // عرض رسائل التحذير
  static void showWarningSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.warning_outlined,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // عرض رسائل المعلومات
  static void showInfoSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.info_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.blue[600],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // عرض حوار خطأ
  static void showErrorDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Cairo',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'حسناً',
              style: TextStyle(
                fontFamily: 'Cairo',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // تسجيل الأخطاء (للتطوير)
  static void logError(String error, [StackTrace? stackTrace]) {
    debugPrint('🔴 خطأ: $error');
    if (stackTrace != null) {
      debugPrint('📍 Stack Trace: $stackTrace');
    }
  }

  // تسجيل التحذيرات (للتطوير)
  static void logWarning(String warning) {
    debugPrint('🟡 تحذير: $warning');
  }

  // تسجيل المعلومات (للتطوير)
  static void logInfo(String info) {
    debugPrint('🔵 معلومات: $info');
  }
}

