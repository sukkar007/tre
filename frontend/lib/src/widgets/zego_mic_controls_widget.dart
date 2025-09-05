import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../services/zego_audio_service.dart';
import '../models/user_model.dart';
import '../models/room_model.dart';
import '../config/zego_config.dart';
import '../utils/app_constants.dart';
import '../utils/error_handler.dart';

/// Widget للتحكم المتقدم في المايك والصوت مع ZegoCloud
class ZegoMicControlsWidget extends StatefulWidget {
  final UserModel currentUser;
  final RoomModel room;
  final Function(String action, Map<String, dynamic> data)? onAction;

  const ZegoMicControlsWidget({
    Key? key,
    required this.currentUser,
    required this.room,
    this.onAction,
  }) : super(key: key);

  @override
  State<ZegoMicControlsWidget> createState() => _ZegoMicControlsWidgetState();
}

class _ZegoMicControlsWidgetState extends State<ZegoMicControlsWidget>
    with TickerProviderStateMixin {
  
  // Controllers
  late AnimationController _micButtonController;
  late AnimationController _speakerButtonController;
  late AnimationController _pulseController;
  late Animation<double> _micButtonAnimation;
  late Animation<double> _speakerButtonAnimation;
  late Animation<double> _pulseAnimation;
  
  // Services
  final ZegoAudioService _zegoService = ZegoAudioService();
  
  // State
  bool isMicrophoneOn = false;
  bool isSpeakerOn = true;
  bool isProcessing = false;
  bool isSpeaking = false;
  double audioLevel = 0.0;
  ZegoRoomState roomState = ZegoRoomState.disconnected;
  
  // Subscriptions
  StreamSubscription? _roomStateSubscription;
  StreamSubscription? _micStatesSubscription;
  Timer? _audioLevelTimer;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeAudioControls();
  }

  /// تهيئة الرسوم المتحركة
  void _initializeAnimations() {
    _micButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _speakerButtonController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _micButtonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _micButtonController,
      curve: Curves.easeInOut,
    ));
    
    _speakerButtonAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
    ).animate(CurvedAnimation(
      parent: _speakerButtonController,
      curve: Curves.easeInOut,
    ));
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  /// تهيئة التحكم في الصوت
  void _initializeAudioControls() {
    // الحصول على الحالة الحالية
    setState(() {
      isMicrophoneOn = _zegoService.isMicrophoneOn;
      isSpeakerOn = _zegoService.isSpeakerOn;
      roomState = _zegoService.currentRoomState;
    });

    // تسجيل مستمعي الأحداث
    _registerEventListeners();
    
    // بدء مراقبة مستوى الصوت
    _startAudioLevelMonitoring();
  }

  /// تسجيل مستمعي الأحداث
  void _registerEventListeners() {
    // حالة الغرفة
    _roomStateSubscription = _zegoService.roomStateStream.listen((state) {
      setState(() {
        roomState = state;
      });
    });

    // حالات المايكات
    _micStatesSubscription = _zegoService.micStatesStream.listen((micStates) {
      final currentUserMicState = micStates[widget.currentUser.id];
      if (currentUserMicState != null) {
        setState(() {
          isMicrophoneOn = currentUserMicState;
          isSpeaking = currentUserMicState;
        });
        
        // تشغيل رسوم متحركة للنبضة عند التحدث
        if (isSpeaking && isMicrophoneOn) {
          _pulseController.repeat(reverse: true);
        } else {
          _pulseController.stop();
          _pulseController.reset();
        }
      }
    });
  }

  /// بدء مراقبة مستوى الصوت
  void _startAudioLevelMonitoring() {
    _audioLevelTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (isMicrophoneOn && roomState == ZegoRoomState.connected) {
        // محاكاة مستوى الصوت (في التطبيق الحقيقي، يتم الحصول عليه من ZegoCloud)
        setState(() {
          audioLevel = isSpeaking ? 0.7 + (0.3 * (DateTime.now().millisecond % 100) / 100) : 0.0;
        });
      } else {
        setState(() {
          audioLevel = 0.0;
        });
      }
    });
  }

  /// تبديل حالة المايك
  Future<void> _toggleMicrophone() async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      // رسوم متحركة للضغط
      await _micButtonController.forward();
      await _micButtonController.reverse();
      
      // تبديل المايك
      await _zegoService.toggleMicrophone();
      
      setState(() {
        isMicrophoneOn = _zegoService.isMicrophoneOn;
      });
      
      // اهتزاز تفاعلي
      HapticFeedback.mediumImpact();
      
      // إشعار نجاح
      ErrorHandler.showSuccessSnackBar(
        context,
        isMicrophoneOn ? 'تم تشغيل المايك' : 'تم إيقاف المايك',
      );
      
      // إرسال إشعار للوالد
      widget.onAction?.call('microphone_toggled', {
        'enabled': isMicrophoneOn,
        'userId': widget.currentUser.id,
      });
      
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        'خطأ في التحكم بالمايك: ${e.toString()}',
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  /// تبديل حالة السماعة
  Future<void> _toggleSpeaker() async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      // رسوم متحركة للضغط
      await _speakerButtonController.forward();
      await _speakerButtonController.reverse();
      
      // تبديل السماعة
      await _zegoService.toggleSpeaker();
      
      setState(() {
        isSpeakerOn = _zegoService.isSpeakerOn;
      });
      
      // اهتزاز تفاعلي
      HapticFeedback.lightImpact();
      
      // إشعار نجاح
      ErrorHandler.showSuccessSnackBar(
        context,
        isSpeakerOn ? 'تم تشغيل السماعة' : 'تم إيقاف السماعة',
      );
      
      // إرسال إشعار للوالد
      widget.onAction?.call('speaker_toggled', {
        'enabled': isSpeakerOn,
        'userId': widget.currentUser.id,
      });
      
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        'خطأ في التحكم بالسماعة: ${e.toString()}',
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  /// طلب الانتقال للمايك
  Future<void> _requestMicAccess() async {
    try {
      // تنفيذ طلب الوصول للمايك
      await _zegoService.startPublishing();
      
      ErrorHandler.showSuccessSnackBar(
        context,
        'تم إرسال طلب الانتقال للمايك',
      );
      
      widget.onAction?.call('mic_access_requested', {
        'userId': widget.currentUser.id,
        'roomId': widget.room.id,
      });
      
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        'خطأ في طلب الوصول للمايك: ${e.toString()}',
      );
    }
  }

  /// مغادرة المايك
  Future<void> _leaveMic() async {
    try {
      await _zegoService.stopPublishing();
      
      ErrorHandler.showSuccessSnackBar(
        context,
        'تم مغادرة المايك',
      );
      
      widget.onAction?.call('mic_left', {
        'userId': widget.currentUser.id,
        'roomId': widget.room.id,
      });
      
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        'خطأ في مغادرة المايك: ${e.toString()}',
      );
    }
  }

  /// عرض إعدادات الصوت المتقدمة
  void _showAdvancedAudioSettings() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAdvancedAudioSettings(),
    );
  }

  /// بناء إعدادات الصوت المتقدمة
  Widget _buildAdvancedAudioSettings() {
    return Container(
      decoration: const BoxDecoration(
        color: AppConstants.cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان
          Row(
            children: [
              const Icon(
                Icons.tune,
                color: AppConstants.primaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              const Text(
                'إعدادات الصوت المتقدمة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // إلغاء الصدى
          _buildAudioSettingTile(
            icon: Icons.graphic_eq,
            title: 'إلغاء الصدى',
            subtitle: 'تحسين جودة الصوت',
            value: true,
            onChanged: (value) async {
              await _zegoService.updateAudioSettings(
                enableEchoCancellation: value,
              );
            },
          ),
          
          // تقليل الضوضاء
          _buildAudioSettingTile(
            icon: Icons.noise_control_off,
            title: 'تقليل الضوضاء',
            subtitle: 'إزالة الأصوات الخلفية',
            value: true,
            onChanged: (value) async {
              await _zegoService.updateAudioSettings(
                enableNoiseSuppression: value,
              );
            },
          ),
          
          // التحكم التلقائي في الصوت
          _buildAudioSettingTile(
            icon: Icons.auto_fix_high,
            title: 'التحكم التلقائي في الصوت',
            subtitle: 'ضبط مستوى الصوت تلقائياً',
            value: true,
            onChanged: (value) async {
              await _zegoService.updateAudioSettings(
                enableAutoGainControl: value,
              );
            },
          ),
          
          const SizedBox(height: 20),
          
          // جودة الصوت
          const Text(
            'جودة الصوت',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          
          const SizedBox(height: 12),
          
          Row(
            children: [
              _buildQualityButton('منخفضة', 'low'),
              const SizedBox(width: 8),
              _buildQualityButton('متوسطة', 'medium'),
              const SizedBox(width: 8),
              _buildQualityButton('عالية', 'high'),
            ],
          ),
          
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  /// بناء عنصر إعداد الصوت
  Widget _buildAudioSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppConstants.primaryColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppConstants.primaryColor,
          ),
        ],
      ),
    );
  }

  /// بناء زر جودة الصوت
  Widget _buildQualityButton(String label, String quality) {
    final isSelected = quality == 'medium'; // افتراضي
    
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          await _zegoService.updateAudioSettings(audioQuality: quality);
          Navigator.pop(context);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? AppConstants.primaryColor 
                : Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.white.withOpacity(0.7),
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  /// بناء مؤشر مستوى الصوت
  Widget _buildAudioLevelIndicator() {
    return Container(
      width: 4,
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.green,
            Colors.yellow,
            Colors.red,
          ],
        ),
      ),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 4,
          height: 40 * audioLevel,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppConstants.cardColor.withOpacity(0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // مؤشر مستوى الصوت
          if (isMicrophoneOn) _buildAudioLevelIndicator(),
          
          // زر المايك
          AnimatedBuilder(
            animation: _micButtonAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _micButtonAnimation.value,
                child: AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: isSpeaking ? _pulseAnimation.value : 1.0,
                      child: GestureDetector(
                        onTap: _toggleMicrophone,
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isMicrophoneOn 
                                ? AppConstants.primaryColor 
                                : Colors.red,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (isMicrophoneOn 
                                    ? AppConstants.primaryColor 
                                    : Colors.red).withOpacity(0.3),
                                blurRadius: 15,
                                spreadRadius: isSpeaking ? 5 : 0,
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                isMicrophoneOn ? Icons.mic : Icons.mic_off,
                                color: Colors.white,
                                size: 28,
                              ),
                              if (isProcessing)
                                const SizedBox(
                                  width: 60,
                                  height: 60,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          
          // زر السماعة
          AnimatedBuilder(
            animation: _speakerButtonAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _speakerButtonAnimation.value,
                child: GestureDetector(
                  onTap: _toggleSpeaker,
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: isSpeakerOn 
                          ? AppConstants.secondaryColor 
                          : Colors.grey,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: (isSpeakerOn 
                              ? AppConstants.secondaryColor 
                              : Colors.grey).withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      isSpeakerOn ? Icons.volume_up : Icons.volume_off,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // زر الإعدادات المتقدمة
          GestureDetector(
            onTap: _showAdvancedAudioSettings,
            child: Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.tune,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          
          // حالة الاتصال
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getConnectionColor().withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getConnectionColor(),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: _getConnectionColor(),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _getConnectionText(),
                  style: TextStyle(
                    color: _getConnectionColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// الحصول على لون حالة الاتصال
  Color _getConnectionColor() {
    switch (roomState) {
      case ZegoRoomState.connected:
        return Colors.green;
      case ZegoRoomState.connecting:
      case ZegoRoomState.reconnecting:
        return Colors.orange;
      case ZegoRoomState.disconnected:
        return Colors.red;
    }
  }

  /// الحصول على نص حالة الاتصال
  String _getConnectionText() {
    switch (roomState) {
      case ZegoRoomState.connected:
        return 'متصل';
      case ZegoRoomState.connecting:
        return 'اتصال';
      case ZegoRoomState.reconnecting:
        return 'إعادة اتصال';
      case ZegoRoomState.disconnected:
        return 'منقطع';
    }
  }

  @override
  void dispose() {
    // إلغاء الاشتراكات
    _roomStateSubscription?.cancel();
    _micStatesSubscription?.cancel();
    _audioLevelTimer?.cancel();
    
    // تنظيف الرسوم المتحركة
    _micButtonController.dispose();
    _speakerButtonController.dispose();
    _pulseController.dispose();
    
    super.dispose();
  }
}

