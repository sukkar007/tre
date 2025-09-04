import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'src/models/user_model.dart';
import 'src/services/mock_auth_service.dart';
import 'src/services/mock_room_service.dart';
import 'src/services/mock_media_service.dart';
import 'src/screens/splash_screen.dart';
import 'src/screens/login_screen.dart';
import 'src/screens/home_screen.dart';
import 'src/utils/app_constants.dart';

void main() async {
  // التأكد من تهيئة Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // تعيين اتجاه الشاشة (عمودي فقط)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // تخصيص شريط الحالة
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // تشغيل النسخة التجريبية مع بيانات وهمية
  runApp(const HUSAppDemo());
}

class HUSAppDemo extends StatelessWidget {
  const HUSAppDemo({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // خدمات تجريبية بدلاً من Firebase
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
        
        // إعدادات التطبيق
        theme: ThemeData(
          // الألوان الأساسية
          primarySwatch: Colors.deepPurple,
          primaryColor: const Color(0xFF6366f1),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF6366f1),
            brightness: Brightness.light,
          ),
          
          // الخطوط
          fontFamily: 'Cairo',
          textTheme: const TextTheme(
            displayLarge: TextStyle(fontFamily: 'Cairo'),
            displayMedium: TextStyle(fontFamily: 'Cairo'),
            displaySmall: TextStyle(fontFamily: 'Cairo'),
            headlineLarge: TextStyle(fontFamily: 'Cairo'),
            headlineMedium: TextStyle(fontFamily: 'Cairo'),
            headlineSmall: TextStyle(fontFamily: 'Cairo'),
            titleLarge: TextStyle(fontFamily: 'Cairo'),
            titleMedium: TextStyle(fontFamily: 'Cairo'),
            titleSmall: TextStyle(fontFamily: 'Cairo'),
            bodyLarge: TextStyle(fontFamily: 'Cairo'),
            bodyMedium: TextStyle(fontFamily: 'Cairo'),
            bodySmall: TextStyle(fontFamily: 'Cairo'),
            labelLarge: TextStyle(fontFamily: 'Cairo'),
            labelMedium: TextStyle(fontFamily: 'Cairo'),
            labelSmall: TextStyle(fontFamily: 'Cairo'),
          ),
          
          // تخصيص المكونات
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF1f2937),
            elevation: 0,
            centerTitle: true,
            systemOverlayStyle: SystemUiOverlayStyle(
              statusBarColor: Colors.transparent,
              statusBarIconBrightness: Brightness.dark,
            ),
          ),
          
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366f1),
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: const Color(0xFF6366f1).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              textStyle: const TextStyle(
                fontFamily: 'Cairo',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF6366f1), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontFamily: 'Cairo',
            ),
            labelStyle: const TextStyle(
              color: Color(0xFF6366f1),
              fontFamily: 'Cairo',
            ),
          ),
          
          cardTheme: CardTheme(
            elevation: 4,
            shadowColor: Colors.black.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(8),
          ),
          
          bottomNavigationBarTheme: const BottomNavigationBarThemeData(
            backgroundColor: Colors.white,
            selectedItemColor: Color(0xFF6366f1),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            elevation: 8,
          ),
          
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF6366f1),
            foregroundColor: Colors.white,
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          
          snackBarTheme: SnackBarThemeData(
            backgroundColor: const Color(0xFF1f2937),
            contentTextStyle: const TextStyle(
              color: Colors.white,
              fontFamily: 'Cairo',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
          ),
          
          dialogTheme: DialogTheme(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            titleTextStyle: const TextStyle(
              color: Color(0xFF1f2937),
              fontSize: 20,
              fontWeight: FontWeight.bold,
              fontFamily: 'Cairo',
            ),
            contentTextStyle: const TextStyle(
              color: Color(0xFF6b7280),
              fontSize: 16,
              fontFamily: 'Cairo',
            ),
          ),
          
          // تخصيص الألوان العامة
          scaffoldBackgroundColor: const Color(0xFFF8FAFC),
          dividerColor: Colors.grey[200],
          
          // تخصيص المؤشرات
          progressIndicatorTheme: const ProgressIndicatorThemeData(
            color: Color(0xFF6366f1),
          ),
          
          // تخصيص التبديل والمربعات
          switchTheme: SwitchThemeData(
            thumbColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const Color(0xFF6366f1);
              }
              return Colors.grey[400];
            }),
            trackColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const Color(0xFF6366f1).withOpacity(0.3);
              }
              return Colors.grey[300];
            }),
          ),
          
          checkboxTheme: CheckboxThemeData(
            fillColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.selected)) {
                return const Color(0xFF6366f1);
              }
              return Colors.transparent;
            }),
            checkColor: MaterialStateProperty.all(Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        
        // الشاشة الأولى
        home: const AppWrapper(),
        
        // إعدادات التنقل
        navigatorKey: GlobalKey<NavigatorState>(),
        
        // معالج الأخطاء
        builder: (context, child) {
          // معالجة أخطاء النصوص والخطوط
          ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
            return Scaffold(
              backgroundColor: const Color(0xFFF8FAFC),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'حدث خطأ غير متوقع',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يرجى إعادة تشغيل التطبيق',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontFamily: 'Cairo',
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        // إعادة تشغيل التطبيق
                        SystemNavigator.pop();
                      },
                      child: const Text(
                        'إعادة التشغيل',
                        style: TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          };
          
          return child ?? const SizedBox.shrink();
        },
      ),
    );
  }
}

class AppWrapper extends StatefulWidget {
  const AppWrapper({super.key});

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
          return const DemoLoginScreen();
        } else {
          return const HomeScreen();
        }
      },
    );
  }
}

/// شاشة تسجيل دخول تجريبية
class DemoLoginScreen extends StatelessWidget {
  const DemoLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = context.read<MockAuthService>();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.purple.shade900,
              Colors.blue.shade900,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // شعار التطبيق
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.mic,
                    size: 60,
                    color: Color(0xFF6366f1),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // عنوان التطبيق
                const Text(
                  'HUS',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Cairo',
                  ),
                ),
                
                const SizedBox(height: 8),
                
                const Text(
                  'نسخة تجريبية',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontFamily: 'Cairo',
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // معلومات النسخة التجريبية
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: 32,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'هذه نسخة تجريبية تعمل ببيانات وهمية',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'لا تحتاج لإعدادات Firebase أو ZegoCloud',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                          fontFamily: 'Cairo',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                // أزرار تسجيل الدخول التجريبي
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await authService.signInDemo();
                    },
                    icon: const Icon(Icons.person),
                    label: const Text(
                      'دخول تجريبي',
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF6366f1),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      await authService.signInWithGoogle();
                    },
                    icon: const Icon(Icons.login),
                    label: const Text(
                      'تسجيل دخول Google (تجريبي)',
                      style: TextStyle(
                        fontSize: 16,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

