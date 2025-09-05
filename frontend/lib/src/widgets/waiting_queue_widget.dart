import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../services/socket_service.dart';
import '../utils/app_constants.dart';

class WaitingQueueWidget extends StatefulWidget {
  final RoomModel room;
  final UserModel currentUser;

  const WaitingQueueWidget({
    Key? key,
    required this.room,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<WaitingQueueWidget> createState() => _WaitingQueueWidgetState();
}

class _WaitingQueueWidgetState extends State<WaitingQueueWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  final SocketService _socketService = SocketService();
  bool isRequestingMic = false;
  bool isInQueue = false;
  int? queuePosition;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _updateQueueStatus();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(WaitingQueueWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateQueueStatus();
  }

  void _updateQueueStatus() {
    final userInQueue = widget.room.waitingQueue.firstWhere(
      (item) => item.userId == widget.currentUser.id,
      orElse: () => widget.room.waitingQueue.first,
    );

    setState(() {
      isInQueue = userInQueue.userId == widget.currentUser.id;
      if (isInQueue) {
        queuePosition = widget.room.waitingQueue.indexOf(userInQueue) + 1;
        _pulseController.repeat(reverse: true);
      } else {
        queuePosition = null;
        _pulseController.stop();
        _pulseController.reset();
      }
    });
  }

  Future<void> _requestMic() async {
    if (isRequestingMic || isInQueue) return;

    setState(() {
      isRequestingMic = true;
    });

    try {
      HapticFeedback.mediumImpact();
      await _socketService.requestMic(widget.room.roomId, null);
      
      _showSuccessSnackBar('تم إضافتك لطابور الانتظار');
    } catch (error) {
      _showErrorSnackBar('فشل في طلب المايك: $error');
    } finally {
      setState(() {
        isRequestingMic = false;
      });
    }
  }

  Future<void> _cancelRequest() async {
    if (!isInQueue) return;

    setState(() {
      isRequestingMic = true;
    });

    try {
      HapticFeedback.lightImpact();
      await _socketService.cancelMicRequest(widget.room.roomId);
      
      _showSuccessSnackBar('تم إلغاء طلب المايك');
    } catch (error) {
      _showErrorSnackBar('فشل في إلغاء الطلب: $error');
    } finally {
      setState(() {
        isRequestingMic = false;
      });
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildQueueHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(AppConstants.primaryColorValue).withOpacity(0.1),
            Color(AppConstants.primaryColorValue).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(AppConstants.primaryColorValue).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.queue,
              color: Color(AppConstants.primaryColorValue),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'طابور الانتظار',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${widget.room.waitingQueue.length} في الانتظار',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          if (isInQueue)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'المركز $queuePosition',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildQueueList() {
    if (widget.room.waitingQueue.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.queue,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'لا يوجد أحد في طابور الانتظار',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 8),
            Text(
              'كن أول من يطلب المايك!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.room.waitingQueue.length,
      separatorBuilder: (context, index) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        final queueItem = widget.room.waitingQueue[index];
        return _buildQueueItem(queueItem, index + 1);
      },
    );
  }

  Widget _buildQueueItem(WaitingQueueItem queueItem, int position) {
    final isCurrentUser = queueItem.userId == widget.currentUser.id;
    final userRole = widget.room.getUserRole(queueItem.userId);
    final roleColor = AppConstants.getRoleColor(userRole);

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isCurrentUser 
            ? Color(AppConstants.primaryColorValue).withOpacity(0.1)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrentUser 
              ? Color(AppConstants.primaryColorValue).withOpacity(0.3)
              : Colors.grey[300]!,
        ),
        boxShadow: isCurrentUser ? [
          BoxShadow(
            color: Color(AppConstants.primaryColorValue).withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ] : [],
      ),
      child: Row(
        children: [
          // رقم الترتيب
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: position <= 3 
                  ? (position == 1 ? Colors.amber : 
                     position == 2 ? Colors.grey[400] : 
                     Colors.orange[300])
                  : Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$position',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: position <= 3 ? Colors.white : Colors.grey[600],
                ),
              ),
            ),
          ),
          
          SizedBox(width: 12),
          
          // صورة المستخدم
          Stack(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: roleColor.withOpacity(0.2),
                backgroundImage: queueItem.userProfilePicture != null
                    ? NetworkImage(queueItem.userProfilePicture!)
                    : null,
                child: queueItem.userProfilePicture == null
                    ? Icon(Icons.person, size: 20, color: roleColor)
                    : null,
              ),
              
              // مؤشر الأولوية
              if (queueItem.priority > 0)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Icon(
                      Icons.priority_high,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          
          SizedBox(width: 12),
          
          // معلومات المستخدم
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  queueItem.userName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isCurrentUser 
                        ? Color(AppConstants.primaryColorValue)
                        : Colors.black87,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      AppConstants.getRoleIcon(userRole),
                      size: 12,
                      color: roleColor,
                    ),
                    SizedBox(width: 4),
                    Text(
                      AppConstants.getRoleDisplayName(userRole),
                      style: TextStyle(
                        fontSize: 12,
                        color: roleColor,
                      ),
                    ),
                    if (queueItem.requestedSeatNumber != null) ...[
                      SizedBox(width: 8),
                      Text(
                        '• مقعد ${queueItem.requestedSeatNumber}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // وقت الانتظار
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatWaitingTime(queueItem.joinedAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              if (isCurrentUser)
                Text(
                  'أنت',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(AppConstants.primaryColorValue),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatWaitingTime(DateTime joinedAt) {
    final now = DateTime.now();
    final difference = now.difference(joinedAt);
    
    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}د';
    } else {
      return '${difference.inHours}س';
    }
  }

  Widget _buildActionButton() {
    // التحقق من وجود المستخدم على مايك
    final isOnMic = widget.room.seats.any(
      (seat) => seat.userId == widget.currentUser.id,
    );

    if (isOnMic) {
      return SizedBox.shrink(); // لا يظهر الزر إذا كان على المايك
    }

    return Container(
      padding: EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: isRequestingMic 
              ? null 
              : (isInQueue ? _cancelRequest : _requestMic),
          style: ElevatedButton.styleFrom(
            backgroundColor: isInQueue ? Colors.orange : Color(AppConstants.primaryColorValue),
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: isInQueue ? 2 : 4,
          ),
          child: isRequestingMic
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('جاري المعالجة...'),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isInQueue ? Icons.cancel : Icons.mic,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      isInQueue ? 'إلغاء الطلب' : 'طلب المايك',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQueueHeader(),
          Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: SingleChildScrollView(
              child: _buildQueueList(),
            ),
          ),
          _buildActionButton(),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }
}

// Helper function لعرض طابور الانتظار
void showWaitingQueue(
  BuildContext context,
  RoomModel room,
  UserModel currentUser,
) {
  HapticFeedback.lightImpact();
  
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => WaitingQueueWidget(
      room: room,
      currentUser: currentUser,
    ),
  );
}

