import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../widgets/mic_seat_widget.dart';
import '../widgets/transparent_user_bar.dart';
import '../widgets/room_chat_widget.dart';
import '../widgets/room_controls_widget.dart';
import '../widgets/room_settings_panel.dart';
import '../widgets/media_control_panel.dart';
import '../widgets/youtube_player_widget.dart';
import '../widgets/audio_player_widget.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../services/socket_service.dart';
import '../services/media_service.dart';
import '../services/media_queue_service.dart';
import '../services/zego_audio_service.dart';
import '../utils/app_constants.dart';

/// شاشة الغرفة الصوتية المحسنة مع ميزات الوسائط
class EnhancedAudioRoomScreen extends StatefulWidget {
  final String roomId;
  final UserModel currentUser;

  const EnhancedAudioRoomScreen({
    Key? key,
    required this.roomId,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<EnhancedAudioRoomScreen> createState() => _EnhancedAudioRoomScreenState();
}

class _EnhancedAudioRoomScreenState extends State<EnhancedAudioRoomScreen>
    with TickerProviderStateMixin {
  
  // Controllers
  late AnimationController _micLayoutController;
  late AnimationController _settingsPanelController;
  late AnimationController _mediaPanelController;
  late Animation<double> _micLayoutAnimation;
  late Animation<Offset> _settingsPanelAnimation;
  late Animation<double> _mediaPanelAnimation;
  
  // State
  RoomModel? room;
  List<UserModel> connectedUsers = [];
  bool isSettingsPanelOpen = false;
  bool isMediaPanelOpen = false;
  bool isLoading = true;
  String? errorMessage;
  
  // Media state
  bool isMediaMinimized = false;
  MediaDisplayMode mediaDisplayMode = MediaDisplayMode.minimized;
  
  // Services
  final SocketService _socketService = SocketService();
  late MediaService _mediaService;
  late MediaQueueService _queueService;
  late ZegoAudioService _zegoService;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeServices();
    _initializeRoom();
  }

  @override
  void dispose() {
    _micLayoutController.dispose();
    _settingsPanelController.dispose();
    _mediaPanelController.dispose();
    _mediaService.reset();
    _queueService.reset();
    _zegoService.leaveRoom();
    super.dispose();
  }

  /// تهيئة الرسوم المتحركة
  void _initializeAnimations() {
    _micLayoutController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _settingsPanelController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    
    _mediaPanelController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    
    _micLayoutAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _micLayoutController,
      curve: Curves.easeInOut,
    ));
    
    _settingsPanelAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _settingsPanelController,
      curve: Curves.easeInOut,
    ));
    
    _mediaPanelAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mediaPanelController,
      curve: Curves.easeInOut,
    ));
  }

  /// تهيئة الخدمات
  void _initializeServices() {
    _mediaService = Provider.of<MediaService>(context, listen: false);
    _queueService = Provider.of<MediaQueueService>(context, listen: false);
    _zegoService = Provider.of<ZegoAudioService>(context, listen: false);
    
    // ربط الخدمات
    _queueService.initialize(_mediaService);
    
    // تهيئة خدمة الوسائط للغرفة
    _mediaService.initializeForRoom(widget.roomId);
  }

  /// تهيئة الغرفة
  Future<void> _initializeRoom() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // الانضمام للغرفة الصوتية
      await _zegoService.joinRoom(
        widget.roomId,
        widget.currentUser.id,
        widget.currentUser.name,
      );

      // تحميل بيانات الغرفة
      await _loadRoomData();
      
      // بدء الرسوم المتحركة
      _micLayoutController.forward();
      
      setState(() {
        isLoading = false;
      });

    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = e.toString();
      });
    }
  }

  /// تحميل بيانات الغرفة
  Future<void> _loadRoomData() async {
    // تحميل معلومات الغرفة من الخادم
    // يمكن إضافة API call هنا
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // الخلفية المتدرجة
            _buildGradientBackground(),
            
            // المحتوى الرئيسي
            if (isLoading)
              _buildLoadingScreen()
            else if (errorMessage != null)
              _buildErrorScreen()
            else
              _buildMainContent(),
            
            // لوحة الإعدادات
            if (isSettingsPanelOpen)
              _buildSettingsPanel(),
            
            // لوحة التحكم في الوسائط
            _buildMediaPanel(),
          ],
        ),
      ),
    );
  }

  /// بناء الخلفية المتدرجة
  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.purple.shade900.withOpacity(0.8),
            Colors.black,
            Colors.blue.shade900.withOpacity(0.6),
          ],
        ),
      ),
    );
  }

  /// بناء شاشة التحميل
  Widget _buildLoadingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'جاري الانضمام للغرفة...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// بناء شاشة الخطأ
  Widget _buildErrorScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 24),
          Text(
            'حدث خطأ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            errorMessage ?? 'خطأ غير معروف',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _initializeRoom,
            child: const Text('إعادة المحاولة'),
          ),
        ],
      ),
    );
  }

  /// بناء المحتوى الرئيسي
  Widget _buildMainContent() {
    return Column(
      children: [
        // شريط المستخدمين الشفاف
        TransparentUserBar(
          users: connectedUsers,
          onSettingsPressed: _toggleSettingsPanel,
          onMediaPressed: _toggleMediaPanel,
        ),
        
        // منطقة الوسائط
        _buildMediaArea(),
        
        // مقاعد الميكروفون
        Expanded(
          child: AnimatedBuilder(
            animation: _micLayoutAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * _micLayoutAnimation.value),
                child: Opacity(
                  opacity: _micLayoutAnimation.value,
                  child: _buildMicSeatsGrid(),
                ),
              );
            },
          ),
        ),
        
        // أدوات التحكم السفلية
        _buildBottomControls(),
      ],
    );
  }

  /// بناء منطقة الوسائط
  Widget _buildMediaArea() {
    return Consumer<MediaService>(
      builder: (context, mediaService, child) {
        final currentContent = mediaService.currentContent;
        
        if (currentContent == null) {
          return const SizedBox.shrink();
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          height: _getMediaAreaHeight(),
          margin: const EdgeInsets.all(16),
          child: _buildMediaPlayer(currentContent.type),
        );
      },
    );
  }

  /// الحصول على ارتفاع منطقة الوسائط
  double _getMediaAreaHeight() {
    switch (mediaDisplayMode) {
      case MediaDisplayMode.minimized:
        return 80;
      case MediaDisplayMode.compact:
        return 160;
      case MediaDisplayMode.expanded:
        return 240;
      case MediaDisplayMode.fullscreen:
        return MediaQuery.of(context).size.height * 0.4;
    }
  }

  /// بناء مشغل الوسائط
  Widget _buildMediaPlayer(String contentType) {
    switch (contentType) {
      case 'youtube':
        return YouTubePlayerWidget(
          showControls: mediaDisplayMode != MediaDisplayMode.minimized,
          allowFullScreen: true,
          onFullScreenToggle: _toggleMediaFullscreen,
        );
      case 'audio_file':
        return AudioPlayerWidget(
          showVisualizer: mediaDisplayMode != MediaDisplayMode.minimized,
          showPlaylist: mediaDisplayMode == MediaDisplayMode.expanded,
          onPlaylistToggle: _toggleMediaPanel,
        );
      default:
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              'نوع وسائط غير مدعوم',
              style: TextStyle(color: Colors.grey[400]),
            ),
          ),
        );
    }
  }

  /// بناء شبكة مقاعد الميكروفون
  Widget _buildMicSeatsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: 8, // عدد المقاعد
        itemBuilder: (context, index) {
          return MicSeatWidget(
            seatIndex: index,
            user: index < connectedUsers.length ? connectedUsers[index] : null,
            isCurrentUser: index < connectedUsers.length && 
                          connectedUsers[index].id == widget.currentUser.id,
            onSeatTap: () => _handleSeatTap(index),
          );
        },
      ),
    );
  }

  /// بناء أدوات التحكم السفلية
  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // دردشة الغرفة
          SizedBox(
            height: 120,
            child: RoomChatWidget(
              roomId: widget.roomId,
              currentUser: widget.currentUser,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // أزرار التحكم
          RoomControlsWidget(
            roomId: widget.roomId,
            currentUser: widget.currentUser,
            isRoomOwner: room?.ownerId == widget.currentUser.id,
            onLeaveRoom: _leaveRoom,
            onToggleMedia: _toggleMediaPanel,
          ),
        ],
      ),
    );
  }

  /// بناء لوحة الإعدادات
  Widget _buildSettingsPanel() {
    return SlideTransition(
      position: _settingsPanelAnimation,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(-2, 0),
            ),
          ],
        ),
        child: RoomSettingsPanel(
          room: room,
          currentUser: widget.currentUser,
          onClose: _toggleSettingsPanel,
        ),
      ),
    );
  }

  /// بناء لوحة التحكم في الوسائط
  Widget _buildMediaPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedBuilder(
        animation: _mediaPanelAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, (1 - _mediaPanelAnimation.value) * 300),
            child: MediaControlPanel(
              isRoomOwner: room?.ownerId == widget.currentUser.id,
              onTogglePanel: _toggleMediaPanel,
            ),
          );
        },
      ),
    );
  }

  /// معالجة النقر على المقعد
  void _handleSeatTap(int seatIndex) {
    // منطق معالجة النقر على المقعد
    HapticFeedback.lightImpact();
  }

  /// تبديل لوحة الإعدادات
  void _toggleSettingsPanel() {
    setState(() {
      isSettingsPanelOpen = !isSettingsPanelOpen;
    });
    
    if (isSettingsPanelOpen) {
      _settingsPanelController.forward();
    } else {
      _settingsPanelController.reverse();
    }
  }

  /// تبديل لوحة الوسائط
  void _toggleMediaPanel() {
    setState(() {
      isMediaPanelOpen = !isMediaPanelOpen;
    });
    
    if (isMediaPanelOpen) {
      _mediaPanelController.forward();
    } else {
      _mediaPanelController.reverse();
    }
  }

  /// تبديل وضع ملء الشاشة للوسائط
  void _toggleMediaFullscreen() {
    setState(() {
      if (mediaDisplayMode == MediaDisplayMode.fullscreen) {
        mediaDisplayMode = MediaDisplayMode.expanded;
      } else {
        mediaDisplayMode = MediaDisplayMode.fullscreen;
      }
    });
  }

  /// تبديل وضع عرض الوسائط
  void _toggleMediaDisplayMode() {
    setState(() {
      switch (mediaDisplayMode) {
        case MediaDisplayMode.minimized:
          mediaDisplayMode = MediaDisplayMode.compact;
          break;
        case MediaDisplayMode.compact:
          mediaDisplayMode = MediaDisplayMode.expanded;
          break;
        case MediaDisplayMode.expanded:
          mediaDisplayMode = MediaDisplayMode.minimized;
          break;
        case MediaDisplayMode.fullscreen:
          mediaDisplayMode = MediaDisplayMode.minimized;
          break;
      }
    });
  }

  /// مغادرة الغرفة
  Future<void> _leaveRoom() async {
    try {
      // إيقاف جميع الخدمات
      await _zegoService.leaveRoom();
      _mediaService.reset();
      _queueService.reset();
      
      // العودة للشاشة السابقة
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      debugPrint('خطأ في مغادرة الغرفة: $e');
    }
  }
}

/// أوضاع عرض الوسائط
enum MediaDisplayMode {
  minimized,  // مصغر
  compact,    // مضغوط
  expanded,   // موسع
  fullscreen, // ملء الشاشة
}

