import 'package:flutter/material.dart';
import 'dart:ui';
import '../models/user_model.dart';
import '../utils/app_constants.dart';

class TransparentUserBar extends StatefulWidget {
  final List<UserModel> connectedUsers;
  final int micCount;

  const TransparentUserBar({
    Key? key,
    required this.connectedUsers,
    required this.micCount,
  }) : super(key: key);

  @override
  State<TransparentUserBar> createState() => _TransparentUserBarState();
}

class _TransparentUserBarState extends State<TransparentUserBar>
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }
  
  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutBack,
    ));
    
    // تشغيل الرسوم المتحركة
    _slideController.forward();
  }
  
  @override
  void didUpdateWidget(TransparentUserBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // إعادة تشغيل الرسوم المتحركة عند تغيير عدد المايكات
    if (widget.micCount != oldWidget.micCount) {
      _slideController.reset();
      _slideController.forward();
    }
  }
  
  double _getBarPosition() {
    // حساب موقع الشريط بناءً على عدد المايكات
    switch (widget.micCount) {
      case 2:
        return 0.45; // أعلى قليلاً للتخطيط البسيط
      case 6:
        return 0.55;
      case 12:
        return 0.65;
      case 16:
        return 0.70;
      case 20:
        return 0.75;
      default:
        return 0.55;
    }
  }
  
  Widget _buildUserAvatar(UserModel user) {
    return Container(
      margin: EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          // الأفاتار
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: _getUserBorderColor(user),
                width: 2,
              ),
              image: user.profilePicture != null
                  ? DecorationImage(
                      image: NetworkImage(user.profilePicture!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: user.profilePicture == null
                ? Icon(
                    Icons.person,
                    size: 24,
                    color: Colors.white,
                  )
                : null,
          ),
          
          // مؤشر الحالة
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: _getUserStatusColor(user),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
          
          // أيقونة الدور (للمدراء والمالك)
          if (user.role == 'owner' || user.role == 'admin')
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: user.role == 'owner' ? Colors.purple : Colors.orange,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1),
                ),
                child: Icon(
                  user.role == 'owner' ? Icons.crown : Icons.admin_panel_settings,
                  size: 10,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  Color _getUserBorderColor(UserModel user) {
    switch (user.role) {
      case 'owner':
        return Colors.purple;
      case 'admin':
        return Colors.orange;
      case 'speaker':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
  
  Color _getUserStatusColor(UserModel user) {
    switch (user.status) {
      case 'online':
        return Colors.green;
      case 'away':
        return Colors.yellow;
      default:
        return Colors.grey;
    }
  }
  
  Widget _buildActivityMessage() {
    // رسائل النشاط المختصرة
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.person_add,
            size: 14,
            color: Colors.green,
          ),
          SizedBox(width: 4),
          Text(
            'انضم مستخدم جديد',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildUserCount() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.people,
            size: 14,
            color: Colors.white,
          ),
          SizedBox(width: 4),
          Text(
            '${widget.connectedUsers.length}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Positioned(
        left: 0,
        right: 0,
        top: MediaQuery.of(context).size.height * _getBarPosition(),
        child: Container(
          height: 60,
          margin: EdgeInsets.symmetric(horizontal: 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // عداد المستخدمين
                      _buildUserCount(),
                      
                      SizedBox(width: 12),
                      
                      // قائمة المستخدمين المتصلين
                      Expanded(
                        child: widget.connectedUsers.isEmpty
                            ? Center(
                                child: Text(
                                  'لا يوجد مستخدمين متصلين',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.7),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: widget.connectedUsers.length,
                                itemBuilder: (context, index) {
                                  final user = widget.connectedUsers[index];
                                  return _buildUserAvatar(user);
                                },
                              ),
                      ),
                      
                      SizedBox(width: 12),
                      
                      // رسالة نشاط (اختيارية)
                      _buildActivityMessage(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }
}

