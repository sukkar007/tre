import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../services/room_permission_service.dart';
import '../utils/app_constants.dart';

class UserActionsSheet extends StatefulWidget {
  final UserModel currentUser;
  final UserModel targetUser;
  final RoomModel room;

  const UserActionsSheet({
    Key? key,
    required this.currentUser,
    required this.targetUser,
    required this.room,
  }) : super(key: key);

  @override
  State<UserActionsSheet> createState() => _UserActionsSheetState();
}

class _UserActionsSheetState extends State<UserActionsSheet>
    with TickerProviderStateMixin {
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  final RoomPermissionService _permissionService = RoomPermissionService();
  List<UserAction> availableActions = [];
  bool isExecuting = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAvailableActions();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _slideController.forward();
  }

  void _loadAvailableActions() {
    setState(() {
      availableActions = _permissionService.getAvailableActionsForUser(
        widget.currentUser,
        widget.targetUser,
        widget.room,
      );
    });
  }

  Future<void> _executeAction(UserAction action) async {
    if (isExecuting) return;

    setState(() {
      isExecuting = true;
    });

    HapticFeedback.mediumImpact();

    try {
      final success = await _permissionService.executeAction(
        action.id,
        widget.currentUser,
        widget.targetUser,
        widget.room,
        context,
      );

      if (success && mounted) {
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        _showErrorSnackBar('فشل في تنفيذ العملية: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          isExecuting = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildUserHeader() {
    final userRole = widget.room.getUserRole(widget.targetUser.id);
    final roleColor = AppConstants.getRoleColor(userRole);
    final roleIcon = AppConstants.getRoleIcon(userRole);
    final roleDisplayName = AppConstants.getRoleDisplayName(userRole);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            roleColor.withOpacity(0.1),
            roleColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          // مؤشر السحب
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),
          
          // صورة المستخدم
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: roleColor.withOpacity(0.2),
                backgroundImage: widget.targetUser.profilePicture != null
                    ? NetworkImage(widget.targetUser.profilePicture!)
                    : null,
                child: widget.targetUser.profilePicture == null
                    ? Icon(Icons.person, size: 40, color: roleColor)
                    : null,
              ),
              
              // أيقونة الدور
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: roleColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Icon(
                    roleIcon,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          // اسم المستخدم
          Text(
            widget.targetUser.displayName,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          SizedBox(height: 4),
          
          // دور المستخدم
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: roleColor.withOpacity(0.3)),
            ),
            child: Text(
              roleDisplayName,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: roleColor,
              ),
            ),
          ),
          
          // معلومات إضافية
          if (widget.targetUser.bio != null) ...[
            SizedBox(height: 8),
            Text(
              widget.targetUser.bio!,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsList() {
    if (availableActions.isEmpty) {
      return Container(
        padding: EdgeInsets.all(40),
        child: Column(
          children: [
            Icon(
              Icons.block,
              size: 48,
              color: Colors.grey[400],
            ),
            SizedBox(height: 16),
            Text(
              'لا توجد إجراءات متاحة',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      itemCount: availableActions.length,
      separatorBuilder: (context, index) => SizedBox(height: 8),
      itemBuilder: (context, index) {
        final action = availableActions[index];
        return _buildActionTile(action);
      },
    );
  }

  Widget _buildActionTile(UserAction action) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isExecuting ? null : () => _executeAction(action),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: action.isDestructive 
                ? Colors.red.withOpacity(0.05)
                : action.color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: action.isDestructive 
                  ? Colors.red.withOpacity(0.2)
                  : action.color.withOpacity(0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: action.isDestructive 
                      ? Colors.red.withOpacity(0.1)
                      : action.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  action.icon,
                  size: 20,
                  color: action.isDestructive ? Colors.red : action.color,
                ),
              ),
              
              SizedBox(width: 12),
              
              Expanded(
                child: Text(
                  action.title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: action.isDestructive 
                        ? Colors.red[700]
                        : Colors.black87,
                  ),
                ),
              ),
              
              if (isExecuting) ...[
                SizedBox(width: 8),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      action.isDestructive ? Colors.red : action.color,
                    ),
                  ),
                ),
              ] else ...[
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey[400],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
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
            _buildUserHeader(),
            _buildActionsList(),
            SizedBox(height: 20),
          ],
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

// Helper function لعرض قائمة الإجراءات
void showUserActionsSheet(
  BuildContext context,
  UserModel currentUser,
  UserModel targetUser,
  RoomModel room,
) {
  HapticFeedback.lightImpact();
  
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => UserActionsSheet(
      currentUser: currentUser,
      targetUser: targetUser,
      room: room,
    ),
  );
}

