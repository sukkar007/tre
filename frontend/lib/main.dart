import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'src/services/auth_service.dart';
import 'src/screens/splash_screen.dart';

void main() async {
  // التأكد من تهيئة Flutter
  WidgetsFlutterBinding.ensureInitialized();
  
  // تهيئة Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
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

  runApp(const HUSApp());
}

class HUSApp extends StatelessWidget {
  const HUSApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthService(),
        ),
      ],
      child: MaterialApp(
        title: 'HUS - تطبيق الدردشة الصوتية',
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
        home: const SplashScreen(),
        
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

