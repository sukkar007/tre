import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/models/user_model.dart';
import 'src/services/mock_auth_service.dart';
import 'src/services/mock_room_service.dart';
import 'src/services/mock_media_service.dart';
import 'src/screens/splash_screen.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/utils/app_constants.dart';

void main() {
  runApp(const HUSAppDemo());
}

class HUSAppDemo extends StatelessWidget {
  const HUSAppDemo({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // خدمات تجريبية
        Provider<MockAuthService>(create: (_) => MockAuthService()),
        Provider<MockRoomService>(create: (_) => MockRoomService()),
        Provider<MockMediaService>(create: (_) => MockMediaService()),
        
        // حالة المصادقة
        StreamProvider<UserModel?>(
          create: (context) => context.read<MockAuthService>().authStateChanges,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'HUS - نسخة تجريبية',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const AppWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/home': (context) => const HomeScreen(),
        },
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      primarySwatch: Colors.blue,
      primaryColor: AppConstants.primaryColor,
      scaffoldBackgroundColor: AppConstants.backgroundColor,
      fontFamily: 'Cairo',
      
      // تخصيص الألوان
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        brightness: Brightness.light,
      ),
      
      // تخصيص AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'Cairo',
        ),
      ),
      
      // تخصيص الأزرار
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            fontFamily: 'Cairo',
          ),
        ),
      ),
      
      // تخصيص حقول الإدخال
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppConstants.primaryColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // تخصيص البطاقات
      cardTheme: CardTheme(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // تخصيص النصوص
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppConstants.textColor,
          fontFamily: 'Cairo',
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: AppConstants.textColor,
          fontFamily: 'Cairo',
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: AppConstants.textColor,
          fontFamily: 'Cairo',
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AppConstants.textColor,
          fontFamily: 'Cairo',
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: AppConstants.textColor,
          fontFamily: 'Cairo',
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: AppConstants.secondaryTextColor,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({Key? key}) : super(key: key);

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // تهيئة الخدمات التجريبية
      final authService = context.read<MockAuthService>();
      final roomService = context.read<MockRoomService>();
      final mediaService = context.read<MockMediaService>();
      
      // تهيئة البيانات التجريبية
      roomService.initializeDemoData();
      mediaService.initializeDemoData();
      
      // محاولة استعادة جلسة المستخدم
      await authService.restoreSession();
      
      // محاكاة تأخير التحميل
      await Future.delayed(const Duration(seconds: 2));
      
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      print('خطأ في تهيئة التطبيق: $e');
      setState(() {
        _isInitialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SplashScreen();
    }

    return Consumer<UserModel?>(
      builder: (context, user, child) {
        if (user == null) {
          return const LoginScreen();
        } else {
          return const HomeScreen();
        }
      },
    );
  }
}

/// شاشة تجريبية لعرض معلومات النسخة التجريبية
class DemoInfoScreen extends StatelessWidget {
  const DemoInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('معلومات النسخة التجريبية'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: AppConstants.primaryColor),
                        const SizedBox(width: 8),
                        Text(
                          'نسخة تجريبية',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'هذه نسخة تجريبية من تطبيق HUS تعمل ببيانات وهمية لأغراض العرض والاختبار.',
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        const SizedBox(width: 8),
                        Text(
                          'الميزات المتاحة',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('✅ تسجيل الدخول التجريبي'),
                    const Text('✅ الغرف الصوتية مع مقاعد تفاعلية'),
                    const Text('✅ دردشة الغرف'),
                    const Text('✅ تشغيل YouTube (محاكاة)'),
                    const Text('✅ تشغيل الملفات الصوتية (محاكاة)'),
                    const Text('✅ قائمة انتظار الوسائط'),
                    const Text('✅ إعدادات الغرفة'),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.orange),
                        const SizedBox(width: 8),
                        Text(
                          'ملاحظات مهمة',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text('⚠️ البيانات وهمية وتختفي عند إعادة تشغيل التطبيق'),
                    const Text('⚠️ الصوت والفيديو محاكاة فقط'),
                    const Text('⚠️ لا يتطلب اتصال بالإنترنت'),
                    const Text('⚠️ للنسخة الكاملة، يرجى إعداد Firebase و ZegoCloud'),
                  ],
                ),
              ),
            ),
            
            const Spacer(),
            
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('العودة للتطبيق'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

