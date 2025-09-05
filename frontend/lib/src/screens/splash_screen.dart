import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/splash_model.dart';
import '../widgets/animated_progress_bar.dart';
import 'login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  
  final ApiService _apiService = ApiService();
  
  // متغيرات الحالة
  SplashContentModel? _splashContent;
  bool _isLoading = true;
  String _loadingText = 'جاري التحميل...';
  
  // متغيرات الرسوم المتحركة
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  // متغيرات شريط التقدم
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSplashContent();
  }

  void _initializeAnimations() {
    // تهيئة متحكمات الرسوم المتحركة
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // تهيئة الرسوم المتحركة
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );
    
    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadSplashContent() async {
    try {
      setState(() {
        _loadingText = 'جاري تحميل المحتوى...';
      });

      // الحصول على معلومات المنصة
      final platform = Platform.isAndroid ? 'android' : 'ios';
      
      // تحميل محتوى شاشة Splash من الخادم
      final splashResponse = await _apiService.getSplashContent(
        platform: platform,
        // يمكن إضافة معلومات إضافية هنا مثل:
        // country: 'SA',
        // language: 'ar',
        // version: '1.0.0',
      );

      if (splashResponse != null && splashResponse.success && splashResponse.content != null) {
        setState(() {
          _splashContent = splashResponse.content;
          _isLoading = false;
          _loadingText = 'مرحباً بك!';
        });
        
        // بدء الرسوم المتحركة
        _startAnimations();
        
        // بدء عملية التحقق من المصادقة
        _initializeApp();
      } else {
        // استخدام محتوى افتراضي في حالة فشل التحميل
        _useDefaultContent();
      }
    } catch (e) {
      print('خطأ في تحميل محتوى Splash: $e');
      _useDefaultContent();
    }
  }

  void _useDefaultContent() {
    setState(() {
      _splashContent = SplashContentModel(
        contentId: 'default_offline',
        title: 'مرحباً بك في HUS',
        subtitle: 'تطبيق الدردشة الصوتية',
        description: 'انضم إلى آلاف المستخدمين في غرف الدردشة التفاعلية',
        colors: SplashColors(
          primary: '#6366f1',
          secondary: '#8b5cf6',
          text: '#ffffff',
          background: '#1f2937',
        ),
        settings: SplashSettings(
          displayDuration: 3000,
          showProgressBar: true,
          animationType: 'fade',
        ),
      );
      _isLoading = false;
      _loadingText = 'مرحباً بك!';
    });
    
    _startAnimations();
    _initializeApp();
  }

  void _startAnimations() {
    if (_splashContent == null) return;

    switch (_splashContent!.settings.animationType) {
      case 'slide':
        _slideController.forward();
        break;
      case 'zoom':
        _scaleController.forward();
        break;
      case 'fade':
      default:
        _fadeController.forward();
        break;
    }

    if (_splashContent!.settings.showProgressBar) {
      _progressController.forward();
    }
  }

  Future<void> _initializeApp() async {
    setState(() {
      _loadingText = 'جاري التحقق من حالة تسجيل الدخول...';
    });

    // تهيئة خدمة المصادقة
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.initialize();

    // انتظار المدة المحددة لعرض شاشة Splash
    final displayDuration = _splashContent?.settings.displayDuration ?? 3000;
    await Future.delayed(Duration(milliseconds: displayDuration));

    // الانتقال إلى الشاشة المناسبة
    if (mounted) {
      if (authService.isLoggedIn) {
        _navigateToHome();
      } else {
        _navigateToLogin();
      }
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const HomeScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _handleAdClick(Advertisement ad) async {
    if (_splashContent != null) {
      // تسجيل النقرة مع الخادم
      await _apiService.recordAdClick(_splashContent!.contentId, ad.adId);
      
      // فتح الرابط إذا كان متوفراً
      if (ad.actionUrl != null && ad.actionUrl!.isNotEmpty) {
        final uri = Uri.parse(ad.actionUrl!);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }
    }
  }

  Color _parseColor(String colorString) {
    try {
      return Color(int.parse(colorString.replaceFirst('#', '0xFF')));
    } catch (e) {
      return Colors.deepPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _splashContent == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF1f2937),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 20),
              Text(
                _loadingText,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      );
    }

    final backgroundColor = _parseColor(_splashContent!.colors.background);
    final primaryColor = _parseColor(_splashContent!.colors.primary);
    final textColor = _parseColor(_splashContent!.colors.text);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        decoration: _splashContent!.backgroundImage != null
            ? BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(_splashContent!.backgroundImage!),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    backgroundColor.withOpacity(0.7),
                    BlendMode.overlay,
                  ),
                ),
              )
            : null,
        child: SafeArea(
          child: Column(
            children: [
              // الإعلانات في الأعلى (إذا وجدت)
              if (_splashContent!.advertisements.isNotEmpty)
                Container(
                  height: 80,
                  margin: const EdgeInsets.all(16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _splashContent!.advertisements.length,
                    itemBuilder: (context, index) {
                      final ad = _splashContent!.advertisements[index];
                      return GestureDetector(
                        onTap: () => _handleAdClick(ad),
                        child: Container(
                          width: 200,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              if (ad.imageUrl != null)
                                ClipRRect(
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(12),
                                    bottomLeft: Radius.circular(12),
                                  ),
                                  child: Image.network(
                                    ad.imageUrl!,
                                    width: 60,
                                    height: 80,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        width: 60,
                                        height: 80,
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image),
                                      );
                                    },
                                  ),
                                ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        ad.title,
                                        style: TextStyle(
                                          color: textColor,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (ad.description != null)
                                        Text(
                                          ad.description!,
                                          style: TextStyle(
                                            color: textColor.withOpacity(0.8),
                                            fontSize: 10,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // المحتوى الرئيسي
              Expanded(
                child: AnimatedBuilder(
                  animation: Listenable.merge([
                    _fadeAnimation,
                    _slideAnimation,
                    _scaleAnimation,
                  ]),
                  builder: (context, child) {
                    Widget content = Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // الشعار
                        if (_splashContent!.logoImage != null)
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                _splashContent!.logoImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      color: primaryColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Icon(
                                      Icons.mic,
                                      size: 60,
                                      color: textColor,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                        const SizedBox(height: 40),

                        // العنوان الرئيسي
                        Text(
                          _splashContent!.title,
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                            fontFamily: 'Cairo',
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // العنوان الفرعي
                        if (_splashContent!.subtitle != null)
                          Text(
                            _splashContent!.subtitle!,
                            style: TextStyle(
                              fontSize: 18,
                              color: textColor.withOpacity(0.8),
                              fontFamily: 'Cairo',
                            ),
                            textAlign: TextAlign.center,
                          ),

                        const SizedBox(height: 12),

                        // الوصف
                        if (_splashContent!.description != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 32),
                            child: Text(
                              _splashContent!.description!,
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor.withOpacity(0.7),
                                fontFamily: 'Cairo',
                              ),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                        const SizedBox(height: 40),

                        // نص التحميل
                        Text(
                          _loadingText,
                          style: TextStyle(
                            fontSize: 16,
                            color: textColor.withOpacity(0.9),
                            fontFamily: 'Cairo',
                          ),
                        ),
                      ],
                    );

                    // تطبيق الرسوم المتحركة حسب النوع
                    switch (_splashContent!.settings.animationType) {
                      case 'slide':
                        return SlideTransition(
                          position: _slideAnimation,
                          child: content,
                        );
                      case 'zoom':
                        return ScaleTransition(
                          scale: _scaleAnimation,
                          child: content,
                        );
                      case 'fade':
                      default:
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: content,
                        );
                    }
                  },
                ),
              ),

              // شريط التقدم
              if (_splashContent!.settings.showProgressBar)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: AnimatedProgressBar(
                    animation: _progressAnimation,
                    color: primaryColor,
                    backgroundColor: textColor.withOpacity(0.2),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _progressController.dispose();
    super.dispose();
  }
}

