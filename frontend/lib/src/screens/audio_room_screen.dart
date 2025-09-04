import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/mic_seat_widget.dart';
import '../widgets/transparent_user_bar.dart';
import '../widgets/room_chat_widget.dart';
import '../widgets/room_controls_widget.dart';
import '../widgets/room_settings_panel.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../services/socket_service.dart';
import '../utils/app_constants.dart';

class AudioRoomScreen extends StatefulWidget {
  final String roomId;
  final UserModel currentUser;

  const AudioRoomScreen({
    Key? key,
    required this.roomId,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<AudioRoomScreen> createState() => _AudioRoomScreenState();
}

class _AudioRoomScreenState extends State<AudioRoomScreen>
    with TickerProviderStateMixin {
  
  // Controllers
  late AnimationController _micLayoutController;
  late AnimationController _settingsPanelController;
  late Animation<double> _micLayoutAnimation;
  late Animation<Offset> _settingsPanelAnimation;
  
  // State
  RoomModel? room;
  List<UserModel> connectedUsers = [];
  bool isSettingsPanelOpen = false;
  bool isLoading = true;
  String? errorMessage;
  
  // Services
  final SocketService _socketService = SocketService();
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeRoom();
    _setupSocketListeners();
  }
  
  void _initializeAnimations() {
    _micLayoutController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _settingsPanelController = AnimationController(
      duration: const Duration(milliseconds: 300),
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
  }
  
  Future<void> _initializeRoom() async {
    try {
      // الاتصال بالغرفة عبر Socket
      await _socketService.connect(widget.currentUser.token);
      await _socketService.joinRoom(widget.roomId);
      
      setState(() {
        isLoading = false;
      });
      
      _micLayoutController.forward();
      
    } catch (error) {
      setState(() {
        isLoading = false;
        errorMessage = 'فشل في الاتصال بالغرفة: $error';
      });
    }
  }
  
  void _setupSocketListeners() {
    // استقبال معلومات الغرفة
    _socketService.onRoomJoined((data) {
      setState(() {
        room = RoomModel.fromJson(data['room']);
        connectedUsers = (data['connectedUsers'] as List?)
            ?.map((user) => UserModel.fromJson(user))
            .toList() ?? [];
      });
    });
    
    // تحديث تخطيط المايكات
    _socketService.onMicLayoutUpdated((data) {
      setState(() {
        if (room != null) {
          room = room!.copyWith(
            seats: (data['newSeats'] as List)
                .map((seat) => MicSeat.fromJson(seat))
                .toList(),
            micCount: data['newCount'],
          );
        }
      });
      
      // رسوم متحركة لتغيير التخطيط
      _micLayoutController.reset();
      _micLayoutController.forward();
      
      // إظهار إشعار التغيير
      _showMicCountChangeNotification(
        data['oldCount'],
        data['newCount'],
        data['affectedUsers'],
      );
    });
    
    // تحديث المستخدمين المتصلين
    _socketService.onUsersUpdate((data) {
      setState(() {
        connectedUsers = (data['connectedUsers'] as List)
            .map((user) => UserModel.fromJson(user))
            .toList();
      });
    });
    
    // تحديث المايكات
    _socketService.onMicUpdate((data) {
      setState(() {
        if (room != null) {
          room = room!.copyWith(
            seats: (data['seats'] as List)
                .map((seat) => MicSeat.fromJson(seat))
                .toList(),
          );
        }
      });
    });
    
    // رسائل جديدة
    _socketService.onNewMessage((data) {
      // سيتم التعامل معها في widget الدردشة
    });
    
    // أخطاء
    _socketService.onError((error) {
      _showErrorSnackBar(error['message']);
    });
  }
  
  void _showMicCountChangeNotification(int oldCount, int newCount, List affectedUsers) {
    HapticFeedback.mediumImpact();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.mic, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'تم تغيير عدد المايكات من $oldCount إلى $newCount',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: AppConstants.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: Duration(seconds: 3),
      ),
    );
    
    if (affectedUsers.isNotEmpty) {
      Future.delayed(Duration(seconds: 1), () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم نقل ${affectedUsers.length} مستخدم إلى طابور الانتظار',
            ),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      });
    }
  }
  
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
  
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
  
  Widget _buildMicLayout() {
    if (room == null) return SizedBox.shrink();
    
    return AnimatedBuilder(
      animation: _micLayoutAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _micLayoutAnimation.value,
          child: _getMicLayoutWidget(),
        );
      },
    );
  }
  
  Widget _getMicLayoutWidget() {
    if (room == null) return SizedBox.shrink();
    
    final micCount = room!.micCount;
    final seats = room!.seats;
    
    switch (micCount) {
      case 2:
        return _build2MicLayout(seats);
      case 6:
        return _build6MicLayout(seats);
      case 12:
        return _build12MicLayout(seats);
      case 16:
        return _build16MicLayout(seats);
      case 20:
        return _build20MicLayout(seats);
      default:
        return _build6MicLayout(seats);
    }
  }
  
  Widget _build2MicLayout(List<MicSeat> seats) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          MicSeatWidget(
            seat: seats[0],
            currentUser: widget.currentUser,
            onTap: () => _handleMicSeatTap(seats[0]),
          ),
          MicSeatWidget(
            seat: seats[1],
            currentUser: widget.currentUser,
            onTap: () => _handleMicSeatTap(seats[1]),
          ),
        ],
      ),
    );
  }
  
  Widget _build6MicLayout(List<MicSeat> seats) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // الصف العلوي - مقعد VIP
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              MicSeatWidget(
                seat: seats[0],
                currentUser: widget.currentUser,
                onTap: () => _handleMicSeatTap(seats[0]),
              ),
            ],
          ),
          SizedBox(height: 30),
          // الصف الأوسط
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MicSeatWidget(
                seat: seats[1],
                currentUser: widget.currentUser,
                onTap: () => _handleMicSeatTap(seats[1]),
              ),
              SizedBox(width: 80), // مساحة في الوسط
              MicSeatWidget(
                seat: seats[2],
                currentUser: widget.currentUser,
                onTap: () => _handleMicSeatTap(seats[2]),
              ),
            ],
          ),
          SizedBox(height: 30),
          // الصف السفلي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MicSeatWidget(
                seat: seats[3],
                currentUser: widget.currentUser,
                onTap: () => _handleMicSeatTap(seats[3]),
              ),
              MicSeatWidget(
                seat: seats[4],
                currentUser: widget.currentUser,
                onTap: () => _handleMicSeatTap(seats[4]),
              ),
              MicSeatWidget(
                seat: seats[5],
                currentUser: widget.currentUser,
                onTap: () => _handleMicSeatTap(seats[5]),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _build12MicLayout(List<MicSeat> seats) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // الصف العلوي - مقاعد VIP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MicSeatWidget(seat: seats[0], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[0])),
              MicSeatWidget(seat: seats[1], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[1])),
            ],
          ),
          SizedBox(height: 20),
          // الصف الثاني
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MicSeatWidget(seat: seats[2], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[2])),
              MicSeatWidget(seat: seats[3], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[3])),
              MicSeatWidget(seat: seats[4], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[4])),
            ],
          ),
          SizedBox(height: 20),
          // الصف الثالث
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MicSeatWidget(seat: seats[5], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[5])),
              MicSeatWidget(seat: seats[6], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[6])),
              MicSeatWidget(seat: seats[7], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[7])),
            ],
          ),
          SizedBox(height: 20),
          // الصف السفلي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MicSeatWidget(seat: seats[8], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[8])),
              MicSeatWidget(seat: seats[9], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[9])),
              MicSeatWidget(seat: seats[10], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[10])),
              MicSeatWidget(seat: seats[11], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[11])),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _build16MicLayout(List<MicSeat> seats) {
    return Container(
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          // الصف العلوي - مقاعد VIP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MicSeatWidget(seat: seats[0], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[0])),
              MicSeatWidget(seat: seats[1], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[1])),
              MicSeatWidget(seat: seats[2], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[2])),
            ],
          ),
          SizedBox(height: 16),
          // الصف الثاني
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MicSeatWidget(seat: seats[3], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[3])),
              MicSeatWidget(seat: seats[4], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[4])),
              MicSeatWidget(seat: seats[5], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[5])),
              MicSeatWidget(seat: seats[6], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[6])),
            ],
          ),
          SizedBox(height: 16),
          // الصف الثالث
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MicSeatWidget(seat: seats[7], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[7])),
              MicSeatWidget(seat: seats[8], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[8])),
              MicSeatWidget(seat: seats[9], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[9])),
              MicSeatWidget(seat: seats[10], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[10])),
            ],
          ),
          SizedBox(height: 16),
          // الصف الرابع
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MicSeatWidget(seat: seats[11], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[11])),
              MicSeatWidget(seat: seats[12], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[12])),
              MicSeatWidget(seat: seats[13], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[13])),
            ],
          ),
          SizedBox(height: 16),
          // الصف السفلي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MicSeatWidget(seat: seats[14], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[14])),
              MicSeatWidget(seat: seats[15], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[15])),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _build20MicLayout(List<MicSeat> seats) {
    return Container(
      padding: EdgeInsets.all(10),
      child: Column(
        children: [
          // الصف العلوي - مقاعد VIP
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MicSeatWidget(seat: seats[0], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[0])),
              MicSeatWidget(seat: seats[1], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[1])),
              MicSeatWidget(seat: seats[2], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[2])),
              MicSeatWidget(seat: seats[3], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[3])),
            ],
          ),
          SizedBox(height: 12),
          // الصف الثاني
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MicSeatWidget(seat: seats[4], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[4])),
              MicSeatWidget(seat: seats[5], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[5])),
              MicSeatWidget(seat: seats[6], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[6])),
              MicSeatWidget(seat: seats[7], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[7])),
              MicSeatWidget(seat: seats[8], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[8])),
            ],
          ),
          SizedBox(height: 12),
          // الصف الثالث
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MicSeatWidget(seat: seats[9], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[9])),
              MicSeatWidget(seat: seats[10], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[10])),
              MicSeatWidget(seat: seats[11], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[11])),
              MicSeatWidget(seat: seats[12], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[12])),
              MicSeatWidget(seat: seats[13], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[13])),
            ],
          ),
          SizedBox(height: 12),
          // الصف الرابع
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MicSeatWidget(seat: seats[14], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[14])),
              MicSeatWidget(seat: seats[15], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[15])),
              MicSeatWidget(seat: seats[16], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[16])),
              MicSeatWidget(seat: seats[17], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[17])),
            ],
          ),
          SizedBox(height: 12),
          // الصف السفلي
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              MicSeatWidget(seat: seats[18], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[18])),
              MicSeatWidget(seat: seats[19], currentUser: widget.currentUser, onTap: () => _handleMicSeatTap(seats[19])),
            ],
          ),
        ],
      ),
    );
  }
  
  void _handleMicSeatTap(MicSeat seat) {
    if (seat.userId == null) {
      // مقعد فارغ - طلب الانتقال
      _socketService.requestMic(widget.roomId, seat.seatNumber);
    } else if (seat.userId == widget.currentUser.id) {
      // مقعد المستخدم الحالي - مغادرة المايك
      _socketService.leaveMic(widget.roomId);
    } else {
      // مقعد مستخدم آخر - إظهار خيارات الإدارة
      _showUserManagementOptions(seat);
    }
  }
  
  void _showUserManagementOptions(MicSeat seat) {
    if (room == null || seat.userId == null) return;
    
    final userRole = room!.getUserRole(widget.currentUser.id);
    if (!['owner', 'admin'].contains(userRole)) return;
    
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
              'إدارة المستخدم',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            _buildManagementOption(
              icon: Icons.mic_off,
              title: seat.isMuted ? 'إلغاء الكتم' : 'كتم المايك',
              color: seat.isMuted ? Colors.green : Colors.orange,
              onTap: () => _toggleUserMute(seat),
            ),
            _buildManagementOption(
              icon: Icons.remove_circle,
              title: 'إنزال من المايك',
              color: Colors.blue,
              onTap: () => _removeUserFromMic(seat),
            ),
            if (userRole == 'owner') ...[
              _buildManagementOption(
                icon: Icons.admin_panel_settings,
                title: 'تعيين كمدير',
                color: Colors.purple,
                onTap: () => _assignAsAdmin(seat),
              ),
              _buildManagementOption(
                icon: Icons.block,
                title: 'طرد من الغرفة',
                color: Colors.red,
                onTap: () => _kickUser(seat),
              ),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildManagementOption({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
  
  void _toggleUserMute(MicSeat seat) {
    // TODO: تنفيذ كتم/إلغاء كتم المستخدم
  }
  
  void _removeUserFromMic(MicSeat seat) {
    // TODO: تنفيذ إنزال المستخدم من المايك
  }
  
  void _assignAsAdmin(MicSeat seat) {
    // TODO: تنفيذ تعيين المستخدم كمدير
  }
  
  void _kickUser(MicSeat seat) {
    // TODO: تنفيذ طرد المستخدم
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
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
              ),
              SizedBox(height: 16),
              Text(
                'جاري الاتصال بالغرفة...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: AppConstants.backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red,
              ),
              SizedBox(height: 16),
              Text(
                errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('العودة'),
              ),
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
                ],
              ),
            ),
          ),
          
          // المحتوى الرئيسي
          SafeArea(
            child: Column(
              children: [
                // شريط العنوان
                _buildAppBar(),
                
                // منطقة المايكات
                Expanded(
                  flex: 3,
                  child: _buildMicLayout(),
                ),
                
                // الشريط الشفاف للمستخدمين
                TransparentUserBar(
                  connectedUsers: connectedUsers,
                  micCount: room?.micCount ?? 6,
                ),
                
                // منطقة الدردشة
                Expanded(
                  flex: 2,
                  child: RoomChatWidget(
                    roomId: widget.roomId,
                    currentUser: widget.currentUser,
                  ),
                ),
                
                // أزرار التحكم
                RoomControlsWidget(
                  room: room,
                  currentUser: widget.currentUser,
                  onSettingsTap: _toggleSettingsPanel,
                ),
              ],
            ),
          ),
          
          // لوحة الإعدادات
          if (isSettingsPanelOpen)
            SlideTransition(
              position: _settingsPanelAnimation,
              child: RoomSettingsPanel(
                room: room,
                currentUser: widget.currentUser,
                onClose: _toggleSettingsPanel,
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.3),
              shape: CircleBorder(),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room?.title ?? 'غرفة صوتية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '${connectedUsers.length} مستخدم متصل',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              // TODO: إظهار معلومات الغرفة
            },
            icon: Icon(Icons.info_outline, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black.withOpacity(0.3),
              shape: CircleBorder(),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    _micLayoutController.dispose();
    _settingsPanelController.dispose();
    _socketService.disconnect();
    super.dispose();
  }
}

