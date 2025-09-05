import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';

class MicSeatWidget extends StatefulWidget {
  final MicSeat seat;
  final UserModel currentUser;
  final VoidCallback onTap;

  const MicSeatWidget({
    Key? key,
    required this.seat,
    required this.currentUser,
    required this.onTap,
  }) : super(key: key);

  @override
  State<MicSeatWidget> createState() => _MicSeatWidgetState();
}

class _MicSeatWidgetState extends State<MicSeatWidget>
    with TickerProviderStateMixin {
  
  late AnimationController _pulseController;
  late AnimationController _scaleController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // تشغيل النبضة للمتحدثين النشطين
    if (widget.seat.userId != null && !widget.seat.isMuted) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(MicSeatWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // تحديث الرسوم المتحركة عند تغيير حالة المقعد
    if (widget.seat.userId != oldWidget.seat.userId ||
        widget.seat.isMuted != oldWidget.seat.isMuted) {
      
      if (widget.seat.userId != null && !widget.seat.isMuted) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  Color _getSeatColor() {
    if (widget.seat.userId == null) {
      // مقعد فارغ
      return widget.seat.isVIP 
          ? AppConstants.vipSeatColor.withOpacity(0.3)
          : AppConstants.emptySeatColor;
    } else if (widget.seat.userId == widget.currentUser.id) {
      // مقعد المستخدم الحالي
      return AppConstants.currentUserSeatColor;
    } else if (widget.seat.isMuted) {
      // مستخدم مكتوم
      return AppConstants.mutedSeatColor;
    } else if (widget.seat.isVIP) {
      // مقعد VIP مشغول
      return AppConstants.vipSeatColor;
    } else {
      // مقعد عادي مشغول
      return AppConstants.occupiedSeatColor;
    }
  }

  Widget _buildSeatContent() {
    if (widget.seat.userId == null) {
      // مقعد فارغ
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            widget.seat.isVIP ? Icons.star : Icons.mic,
            size: 24,
            color: Colors.white.withOpacity(0.7),
          ),
          SizedBox(height: 4),
          Text(
            '${widget.seat.seatNumber}',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      );
    } else {
      // مقعد مشغول
      return Stack(
        children: [
          // صورة المستخدم
          Center(
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white,
                  width: 2,
                ),
                image: widget.seat.user?.profilePicture != null
                    ? DecorationImage(
                        image: NetworkImage(widget.seat.user!.profilePicture!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: widget.seat.user?.profilePicture == null
                  ? Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.white,
                    )
                  : null,
            ),
          ),
          
          // رقم المقعد
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${widget.seat.seatNumber}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          
          // أيقونة الكتم
          if (widget.seat.isMuted)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Icon(
                  Icons.mic_off,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          
          // أيقونة VIP
          if (widget.seat.isVIP)
            Positioned(
              top: 0,
              left: 0,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.amber,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Icon(
                  Icons.star,
                  size: 12,
                  color: Colors.white,
                ),
              ),
            ),
          
          // مؤشر التحدث
          if (widget.seat.userId != null && !widget.seat.isMuted)
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppConstants.speakingIndicatorColor,
                        width: 2 * _pulseAnimation.value,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      );
    }
  }

  Widget _buildUserName() {
    if (widget.seat.userId == null || widget.seat.user == null) {
      return SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(top: 8),
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.seat.user!.displayName,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    
    setState(() {
      _isPressed = true;
    });
    
    _scaleController.forward().then((_) {
      _scaleController.reverse();
      setState(() {
        _isPressed = false;
      });
    });
    
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _getSeatColor(),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                      if (widget.seat.userId == widget.currentUser.id)
                        BoxShadow(
                          color: AppConstants.currentUserSeatColor.withOpacity(0.5),
                          blurRadius: 16,
                          offset: Offset(0, 0),
                        ),
                    ],
                    border: Border.all(
                      color: widget.seat.isVIP 
                          ? Colors.amber 
                          : Colors.white.withOpacity(0.3),
                      width: widget.seat.isVIP ? 2 : 1,
                    ),
                  ),
                  child: _buildSeatContent(),
                ),
                _buildUserName(),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}

