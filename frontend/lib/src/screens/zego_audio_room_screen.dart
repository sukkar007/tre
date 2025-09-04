import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../services/zego_audio_service.dart';
import '../services/socket_service.dart';
import '../widgets/mic_seat_widget.dart';
import '../widgets/transparent_user_bar.dart';
import '../widgets/room_chat_widget.dart';
import '../widgets/room_controls_widget.dart';
import '../widgets/room_settings_panel.dart';
import '../config/zego_config.dart';
import '../utils/app_constants.dart';
import '../utils/error_handler.dart';

/// شاشة الغرفة الصوتية مع دمج ZegoCloud
class ZegoAudioRoomScreen extends StatefulWidget {
  final String roomId;
  final UserModel currentUser;
  final String userRole; // 'host', 'speaker', 'audience'

  const ZegoAudioRoomScreen({
    Key? key,
    required this.roomId,
    required this.currentUser,
    this.userRole = 'audience',
  }) : super(key: key);

  @override
  State<ZegoAudioRoomScreen> createState() => _ZegoAudioRoomScreenState();
}

class _ZegoAudioRoomScreenState extends State<ZegoAudioRoomScreen>
    with TickerProviderStateMixin {
  
  // Controllers
  late AnimationController _micLayoutController;
  late AnimationController _settingsPanelController;
  late AnimationController _connectionController;
  late Animation<double> _micLayoutAnimation;
  late Animation<Offset> _settingsPanelAnimation;
  late Animation<double> _connectionAnimation;
  
  // State
  RoomModel? room;
  List<UserModel> connectedUsers = [];
  Map<String, bool> micStates = {};
  bool isSettingsPanelOpen = false;
  bool isLoading = true;
  bool isConnecting = false;
  String? errorMessage;
  ZegoRoomState roomState = ZegoRoomState.disconnected;
  
  // Services
  final ZegoAudioService _zegoService = ZegoAudioService();
  final SocketService _socketService = SocketService();
  
  // Subscriptions
  StreamSubscription? _roomStateSubscription;
  StreamSubscription? _usersSubscription;
  StreamSubscription? _micStatesSubscription;
  StreamSubscription? _messagesSubscription;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeZegoCloud();
  }

  /// تهيئة الرسوم المتحركة
  void _initializeAnimations() {
    _micLayoutController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _settingsPanelController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _connectionController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _micLayoutAnimation = CurvedAnimation(
      parent: _micLayoutController,
      curve: Curves.elasticOut,
    );
    
    _settingsPanelAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _settingsPanelController,
      curve: Curves.easeInOut,
    ));
    
    _connectionAnimation = CurvedAnimation(
      parent: _connectionController,
      curve: Curves.easeInOut,
    );
  }

  /// تهيئة ZegoCloud والاتصال بالغرفة
  Future<void> _initializeZegoCloud() async {
    setState(() {
      isLoading = true;
      isConnecting = true;
    });

    try {
      // التحقق من إعدادات ZegoCloud
      if (!ZegoConfig.isConfigValid()) {
        throw Exception(ZegoConfig.getConfigErrorMessage());
      }

      // تهيئة ZegoCloud
      final initialized = await _zegoService.initialize();
      if (!initialized) {
        throw Exception('فشل في تهيئة ZegoCloud');
      }

      // تسجيل مستمعي الأحداث
      _registerZegoEventListeners();

      // الاتصال بالغرفة
      await _joinRoom();

      // تشغيل رسوم متحركة للاتصال
      _connectionController.forward();

    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
        isConnecting = false;
      });
      
      ErrorHandler.showErrorSnackBar(
        context,
        'خطأ في الاتصال: ${e.toString()}',
      );
    }
  }

  /// تسجيل مستمعي أحداث ZegoCloud
  void _registerZegoEventListeners() {
    // حالة الغرفة
    _roomStateSubscription = _zegoService.roomStateStream.listen((state) {
      setState(() {
        roomState = state;
        isConnecting = state == ZegoRoomState.connecting || 
                      state == ZegoRoomState.reconnecting;
        
        if (state == ZegoRoomState.connected) {
          isLoading = false;
          _micLayoutController.forward();
        }
      });
    });

    // المستخدمون المتصلون
    _usersSubscription = _zegoService.usersStream.listen((zegoUsers) {
      setState(() {
        // تحويل ZegoUIKitUser إلى UserModel
        connectedUsers = zegoUsers.map((zegoUser) => UserModel(
          id: zegoUser.id,
          displayName: zegoUser.name,
          email: '', // سيتم تحديثه من الخادم
          profilePictureUrl: '', // سيتم تحديثه من الخادم
          phoneNumber: '',
          deviceInfo: {},
          createdAt: DateTime.now(),
        )).toList();
      });
    });

    // حالات المايكات
    _micStatesSubscription = _zegoService.micStatesStream.listen((states) {
      setState(() {
        micStates = states;
      });
    });

    // الرسائل
    _messagesSubscription = _zegoService.messagesStream.listen((message) {
      // إضافة الرسالة إلى الدردشة
      // يمكن تنفيذها لاحقاً
    });
  }

  /// الانضمام إلى الغرفة
  Future<void> _joinRoom() async {
    final success = await _zegoService.joinRoom(
      roomID: widget.roomId,
      user: widget.currentUser,
      userRole: widget.userRole,
    );

    if (!success) {
      throw Exception('فشل في الانضمام إلى الغرفة');
    }

    // تحديث معلومات الغرفة من الخادم
    await _loadRoomInfo();
  }

  /// تحميل معلومات الغرفة من الخادم
  Future<void> _loadRoomInfo() async {
    try {
      // هنا يمكن تحميل معلومات الغرفة من الخادم
      // مؤقتاً سنستخدم بيانات وهمية
      setState(() {
        room = RoomModel(
          id: widget.roomId,
          title: 'غرفة صوتية تجريبية',
          description: 'غرفة للاختبار مع ZegoCloud',
          ownerId: widget.currentUser.id,
          category: 'عام',
          micCount: 6,
          seats: [],
          connectedUsers: [],
          settings: RoomSettings(),
          stats: RoomStats(),
          waitingQueue: [],
          bannedUsers: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      });
    } catch (e) {
      print('خطأ في تحميل معلومات الغرفة: $e');
    }
  }

  /// مغادرة الغرفة
  Future<void> _leaveRoom() async {
    try {
      await _zegoService.leaveRoom();
      
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        'خطأ في مغادرة الغرفة: ${e.toString()}',
      );
    }
  }

  /// تبديل حالة المايك
  Future<void> _toggleMicrophone() async {
    try {
      await _zegoService.toggleMicrophone();
      
      HapticFeedback.lightImpact();
      
      ErrorHandler.showSuccessSnackBar(
        context,
        _zegoService.isMicrophoneOn ? 'تم تشغيل المايك' : 'تم إيقاف المايك',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        'خطأ في التحكم بالمايك: ${e.toString()}',
      );
    }
  }

  /// تبديل حالة السماعة
  Future<void> _toggleSpeaker() async {
    try {
      await _zegoService.toggleSpeaker();
      
      HapticFeedback.lightImpact();
      
      ErrorHandler.showSuccessSnackBar(
        context,
        _zegoService.isSpeakerOn ? 'تم تشغيل السماعة' : 'تم إيقاف السماعة',
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        'خطأ في التحكم بالسماعة: ${e.toString()}',
      );
    }
  }

  /// فتح/إغلاق لوحة الإعدادات
  void _toggleSettingsPanel() {
    setState(() {
      isSettingsPanelOpen = !isSettingsPanelOpen;
    });
    
    if (isSettingsPanelOpen) {
      _settingsPanelController.forward();
    } else {
      _settingsPanelController.reverse();
    }
    
    HapticFeedback.selectionClick();
  }

  /// بناء مؤشر الاتصال
  Widget _buildConnectionIndicator() {
    if (!isConnecting) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _connectionAnimation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.white.withOpacity(_connectionAnimation.value),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _getConnectionText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// الحصول على نص حالة الاتصال
  String _getConnectionText() {
    switch (roomState) {
      case ZegoRoomState.connecting:
        return 'جاري الاتصال...';
      case ZegoRoomState.reconnecting:
        return 'جاري إعادة الاتصال...';
      case ZegoRoomState.connected:
        return 'متصل';
      case ZegoRoomState.disconnected:
        return 'منقطع';
    }
  }

  /// بناء مؤشر جودة الصوت
  Widget _buildAudioQualityIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _zegoService.isMicrophoneOn ? Icons.mic : Icons.mic_off,
            size: 16,
            color: _zegoService.isMicrophoneOn ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Icon(
            _zegoService.isSpeakerOn ? Icons.volume_up : Icons.volume_off,
            size: 16,
            color: _zegoService.isSpeakerOn ? Colors.blue : Colors.grey,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                'جاري تحميل الغرفة الصوتية...',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 16,
                ),
              ),
              if (errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppConstants.backgroundColor,
      body: Stack(
        children: [
          // الخلفية المتدرجة
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppConstants.primaryColor.withOpacity(0.1),
                  AppConstants.backgroundColor,
                  AppConstants.secondaryColor.withOpacity(0.1),
                ],
              ),
            ),
          ),

          // المحتوى الرئيسي
          SafeArea(
            child: Column(
              children: [
                // شريط علوي
                _buildTopBar(),
                
                // منطقة المايكات
                Expanded(
                  flex: 3,
                  child: _buildMicSeatsArea(),
                ),
                
                // الشريط الشفاف للمستخدمين
                _buildTransparentUserBar(),
                
                // منطقة الدردشة
                Expanded(
                  flex: 2,
                  child: _buildChatArea(),
                ),
                
                // أزرار التحكم
                _buildControlsArea(),
              ],
            ),
          ),

          // مؤشر الاتصال
          Positioned(
            top: MediaQuery.of(context).padding.top + 60,
            left: 0,
            right: 0,
            child: Center(child: _buildConnectionIndicator()),
          ),

          // لوحة الإعدادات
          if (isSettingsPanelOpen)
            _buildSettingsPanel(),
        ],
      ),
    );
  }

  /// بناء الشريط العلوي
  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // زر الرجوع
          IconButton(
            onPressed: _leaveRoom,
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // معلومات الغرفة
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room?.title ?? 'غرفة صوتية',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${connectedUsers.length} مشارك',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // مؤشر جودة الصوت
          _buildAudioQualityIndicator(),
        ],
      ),
    );
  }

  /// بناء منطقة المايكات
  Widget _buildMicSeatsArea() {
    if (room == null) return const SizedBox.shrink();

    return AnimatedBuilder(
      animation: _micLayoutAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_micLayoutAnimation.value * 0.2),
          child: Opacity(
            opacity: _micLayoutAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(16),
              child: _buildMicLayout(room!.micCount),
            ),
          ),
        );
      },
    );
  }

  /// بناء تخطيط المايكات
  Widget _buildMicLayout(int micCount) {
    // تخطيط المايكات حسب العدد
    switch (micCount) {
      case 2:
        return _buildTwoMicLayout();
      case 6:
        return _buildSixMicLayout();
      case 12:
        return _buildTwelveMicLayout();
      case 16:
        return _buildSixteenMicLayout();
      case 20:
        return _buildTwentyMicLayout();
      default:
        return _buildSixMicLayout();
    }
  }

  /// تخطيط مايكين
  Widget _buildTwoMicLayout() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildMicSeat(0),
        _buildMicSeat(1),
      ],
    );
  }

  /// تخطيط 6 مايكات
  Widget _buildSixMicLayout() {
    return Column(
      children: [
        // الصف الأول
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMicSeat(0),
            _buildMicSeat(1),
          ],
        ),
        const SizedBox(height: 20),
        // الصف الثاني
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMicSeat(2),
            _buildMicSeat(3),
          ],
        ),
        const SizedBox(height: 20),
        // الصف الثالث
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMicSeat(4),
            _buildMicSeat(5),
          ],
        ),
      ],
    );
  }

  /// تخطيط 12 مايك
  Widget _buildTwelveMicLayout() {
    return Column(
      children: [
        // الصف الأول
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMicSeat(0),
            _buildMicSeat(1),
            _buildMicSeat(2),
          ],
        ),
        const SizedBox(height: 16),
        // الصف الثاني
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMicSeat(3),
            _buildMicSeat(4),
            _buildMicSeat(5),
          ],
        ),
        const SizedBox(height: 16),
        // الصف الثالث
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMicSeat(6),
            _buildMicSeat(7),
            _buildMicSeat(8),
          ],
        ),
        const SizedBox(height: 16),
        // الصف الرابع
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMicSeat(9),
            _buildMicSeat(10),
            _buildMicSeat(11),
          ],
        ),
      ],
    );
  }

  /// تخطيط 16 مايك
  Widget _buildSixteenMicLayout() {
    return Column(
      children: [
        for (int row = 0; row < 4; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int col = 0; col < 4; col++)
                  _buildMicSeat(row * 4 + col),
              ],
            ),
          ),
      ],
    );
  }

  /// تخطيط 20 مايك
  Widget _buildTwentyMicLayout() {
    return Column(
      children: [
        for (int row = 0; row < 4; row++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (int col = 0; col < 5; col++)
                  _buildMicSeat(row * 5 + col),
              ],
            ),
          ),
      ],
    );
  }

  /// بناء مقعد مايك
  Widget _buildMicSeat(int seatIndex) {
    // البحث عن المستخدم في هذا المقعد
    UserModel? seatUser;
    bool isVIP = seatIndex < 2; // أول مقعدين VIP
    bool isMuted = micStates[seatUser?.id] == false;
    bool isSpeaking = micStates[seatUser?.id] == true;

    return MicSeatWidget(
      seatNumber: seatIndex + 1,
      user: seatUser,
      isVIP: isVIP,
      isMuted: isMuted,
      isSpeaking: isSpeaking,
      isCurrentUser: seatUser?.id == widget.currentUser.id,
      onTap: () => _handleMicSeatTap(seatIndex, seatUser),
      onLongPress: () => _handleMicSeatLongPress(seatIndex, seatUser),
    );
  }

  /// التعامل مع النقر على مقعد المايك
  void _handleMicSeatTap(int seatIndex, UserModel? user) {
    if (user == null) {
      // مقعد فارغ - طلب الانتقال إليه
      _requestMicSeat(seatIndex);
    } else if (user.id == widget.currentUser.id) {
      // المستخدم الحالي - تبديل المايك
      _toggleMicrophone();
    }
  }

  /// التعامل مع الضغط المطول على مقعد المايك
  void _handleMicSeatLongPress(int seatIndex, UserModel? user) {
    if (user != null && user.id != widget.currentUser.id) {
      // عرض خيارات إدارة المستخدم
      _showUserActionsSheet(user);
    }
  }

  /// طلب الانتقال إلى مقعد المايك
  void _requestMicSeat(int seatIndex) {
    // تنفيذ طلب الانتقال للمايك
    ErrorHandler.showInfoSnackBar(
      context,
      'تم إرسال طلب الانتقال للمايك ${seatIndex + 1}',
    );
  }

  /// عرض خيارات إدارة المستخدم
  void _showUserActionsSheet(UserModel user) {
    // عرض قائمة خيارات المستخدم
    // يمكن تنفيذها لاحقاً
  }

  /// بناء الشريط الشفاف للمستخدمين
  Widget _buildTransparentUserBar() {
    return TransparentUserBar(
      connectedUsers: connectedUsers,
      micCount: room?.micCount ?? 6,
    );
  }

  /// بناء منطقة الدردشة
  Widget _buildChatArea() {
    return RoomChatWidget(
      roomId: widget.roomId,
      currentUser: widget.currentUser,
      isChatEnabled: room?.settings.chatSettings.enabled ?? true,
    );
  }

  /// بناء منطقة التحكم
  Widget _buildControlsArea() {
    return RoomControlsWidget(
      currentUser: widget.currentUser,
      room: room,
      isMicrophoneOn: _zegoService.isMicrophoneOn,
      isSpeakerOn: _zegoService.isSpeakerOn,
      onMicrophoneToggle: _toggleMicrophone,
      onSpeakerToggle: _toggleSpeaker,
      onLeaveMic: () {
        // تنفيذ مغادرة المايك
      },
      onInviteFriends: () {
        // تنفيذ دعوة الأصدقاء
      },
      onSettings: _toggleSettingsPanel,
      onMoreOptions: () {
        // تنفيذ المزيد من الخيارات
      },
    );
  }

  /// بناء لوحة الإعدادات
  Widget _buildSettingsPanel() {
    return SlideTransition(
      position: _settingsPanelAnimation,
      child: RoomSettingsPanel(
        room: room!,
        currentUser: widget.currentUser,
        onClose: _toggleSettingsPanel,
        onRoomUpdated: (updatedRoom) {
          setState(() {
            room = updatedRoom;
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    // إلغاء الاشتراكات
    _roomStateSubscription?.cancel();
    _usersSubscription?.cancel();
    _micStatesSubscription?.cancel();
    _messagesSubscription?.cancel();
    
    // تنظيف الرسوم المتحركة
    _micLayoutController.dispose();
    _settingsPanelController.dispose();
    _connectionController.dispose();
    
    // تنظيف ZegoCloud
    _zegoService.dispose();
    
    super.dispose();
  }
}

