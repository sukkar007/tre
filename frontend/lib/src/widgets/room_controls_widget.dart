import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../services/socket_service.dart';
import '../utils/app_constants.dart';

class RoomControlsWidget extends StatefulWidget {
  final RoomModel? room;
  final UserModel currentUser;
  final VoidCallback onSettingsTap;

  const RoomControlsWidget({
    Key? key,
    required this.room,
    required this.currentUser,
    required this.onSettingsTap,
  }) : super(key: key);

  @override
  State<RoomControlsWidget> createState() => _RoomControlsWidgetState();
}

class _RoomControlsWidgetState extends State<RoomControlsWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _micController;
  late AnimationController _settingsController;
  late Animation<double> _micPulseAnimation;
  late Animation<double> _settingsRotateAnimation;
  
  bool isMicOn = false;
  bool isOnMic = false;
  bool isLoading = false;
  
  final SocketService _socketService = SocketService();

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _updateMicStatus();
  }

  void _initializeAnimations() {
    _micController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _settingsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _micPulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _micController,
      curve: Curves.easeInOut,
    ));

    _settingsRotateAnimation = Tween<double>(
      begin: 0.0,
      end: 0.5,
    ).animate(CurvedAnimation(
      parent: _settingsController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(RoomControlsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateMicStatus();
  }

  void _updateMicStatus() {
    if (widget.room != null) {
      final userSeat = widget.room!.seats.firstWhere(
        (seat) => seat.userId == widget.currentUser.id,
        orElse: () => widget.room!.seats.first,
      );
      
      setState(() {
        isOnMic = userSeat.userId == widget.currentUser.id;
        isMicOn = isOnMic && !userSeat.isMuted;
      });

      if (isMicOn) {
        _micController.repeat(reverse: true);
      } else {
        _micController.stop();
        _micController.reset();
      }
    }
  }

  Future<void> _toggleMic() async {
    if (widget.room == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      HapticFeedback.mediumImpact();

      if (isOnMic) {
        // إذا كان على المايك، تبديل الكتم
        await _socketService.toggleUserMute(
          widget.room!.roomId,
          widget.currentUser.id,
          isMicOn,
        );
      } else {
        // إذا لم يكن على المايك، طلب الانتقال
        await _socketService.requestMic(widget.room!.roomId, 1);
      }

    } catch (error) {
      _showErrorSnackBar('فشل في تنفيذ العملية: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _leaveMic() async {
    if (widget.room == null || !isOnMic) return;

    setState(() {
      isLoading = true;
    });

    try {
      HapticFeedback.lightImpact();
      await _socketService.leaveMic(widget.room!.roomId);
    } catch (error) {
      _showErrorSnackBar('فشل في مغادرة المايك: $error');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _onSettingsTap() {
    HapticFeedback.lightImpact();
    _settingsController.forward().then((_) {
      _settingsController.reverse();
    });
    widget.onSettingsTap();
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
    bool isLoading = false,
    Widget? customIcon,
  }) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: isActive ? color : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
            if (isActive)
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 16,
                offset: Offset(0, 0),
              ),
          ],
          border: Border.all(
            color: isActive ? Colors.white : color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: isLoading
            ? Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isActive ? Colors.white : color,
                    ),
                  ),
                ),
              )
            : customIcon ?? Icon(
                icon,
                color: isActive ? Colors.white : color,
                size: 24,
              ),
      ),
    );
  }

  Widget _buildMicButton() {
    return AnimatedBuilder(
      animation: _micPulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isMicOn ? _micPulseAnimation.value : 1.0,
          child: _buildControlButton(
            icon: isOnMic 
                ? (isMicOn ? Icons.mic : Icons.mic_off)
                : Icons.mic,
            label: isOnMic 
                ? (isMicOn ? 'كتم' : 'إلغاء الكتم')
                : 'طلب المايك',
            color: isOnMic 
                ? (isMicOn ? Colors.green : Colors.red)
                : AppConstants.primaryColor,
            onTap: _toggleMic,
            isActive: isMicOn,
            isLoading: isLoading,
          ),
        );
      },
    );
  }

  Widget _buildLeaveMicButton() {
    if (!isOnMic) return SizedBox.shrink();

    return _buildControlButton(
      icon: Icons.exit_to_app,
      label: 'مغادرة المايك',
      color: Colors.orange,
      onTap: _leaveMic,
      isLoading: isLoading,
    );
  }

  Widget _buildSettingsButton() {
    final userRole = widget.room?.getUserRole(widget.currentUser.id) ?? 'listener';
    final canAccessSettings = ['owner', 'admin'].contains(userRole);

    if (!canAccessSettings) return SizedBox.shrink();

    return AnimatedBuilder(
      animation: _settingsRotateAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _settingsRotateAnimation.value * 2 * 3.14159,
          child: _buildControlButton(
            icon: Icons.settings,
            label: 'الإعدادات',
            color: Colors.purple,
            onTap: _onSettingsTap,
          ),
        );
      },
    );
  }

  Widget _buildInviteButton() {
    return _buildControlButton(
      icon: Icons.person_add,
      label: 'دعوة',
      color: Colors.blue,
      onTap: () {
        // TODO: إظهار قائمة الأصدقاء للدعوة
        HapticFeedback.lightImpact();
        _showInviteDialog();
      },
    );
  }

  void _showInviteDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'دعوة أصدقاء',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.share, color: AppConstants.primaryColor),
              title: Text('مشاركة رابط الغرفة'),
              onTap: () {
                Navigator.pop(context);
                // TODO: مشاركة رابط الغرفة
              },
            ),
            ListTile(
              leading: Icon(Icons.people, color: Colors.blue),
              title: Text('دعوة من قائمة الأصدقاء'),
              onTap: () {
                Navigator.pop(context);
                // TODO: إظهار قائمة الأصدقاء
              },
            ),
            ListTile(
              leading: Icon(Icons.qr_code, color: Colors.green),
              title: Text('رمز QR للغرفة'),
              onTap: () {
                Navigator.pop(context);
                // TODO: إظهار رمز QR
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreButton() {
    return _buildControlButton(
      icon: Icons.more_horiz,
      label: 'المزيد',
      color: Colors.grey[600]!,
      onTap: () {
        HapticFeedback.lightImpact();
        _showMoreOptions();
      },
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'خيارات إضافية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.volume_up, color: Colors.blue),
              title: Text('إعدادات الصوت'),
              onTap: () {
                Navigator.pop(context);
                // TODO: إظهار إعدادات الصوت
              },
            ),
            ListTile(
              leading: Icon(Icons.report, color: Colors.red),
              title: Text('الإبلاغ عن الغرفة'),
              onTap: () {
                Navigator.pop(context);
                // TODO: إظهار نموذج الإبلاغ
              },
            ),
            ListTile(
              leading: Icon(Icons.exit_to_app, color: Colors.orange),
              title: Text('مغادرة الغرفة'),
              onTap: () {
                Navigator.pop(context);
                _showLeaveConfirmation();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('مغادرة الغرفة'),
        content: Text('هل أنت متأكد من رغبتك في مغادرة الغرفة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // العودة للشاشة السابقة
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('مغادرة'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildMicButton(),
            _buildLeaveMicButton(),
            _buildInviteButton(),
            _buildSettingsButton(),
            _buildMoreButton(),
          ].where((widget) => widget is! SizedBox || widget.width != 0).toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _micController.dispose();
    _settingsController.dispose();
    super.dispose();
  }
}

