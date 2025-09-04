import 'package:flutter/material.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';
import 'socket_service.dart';

class RoomPermissionService {
  static final RoomPermissionService _instance = RoomPermissionService._internal();
  factory RoomPermissionService() => _instance;
  RoomPermissionService._internal();

  final SocketService _socketService = SocketService();

  // التحقق من الصلاحيات
  bool canPerformAction(String userRole, String action) {
    return AppConstants.canPerformAction(userRole, action);
  }

  // التحقق من إمكانية تعديل إعدادات الغرفة
  bool canModifyRoomSettings(UserModel user, RoomModel room) {
    final userRole = room.getUserRole(user.id);
    return userRole == AppConstants.roleOwner || userRole == AppConstants.roleAdmin;
  }

  // التحقق من إمكانية كتم المستخدم
  bool canMuteUser(UserModel currentUser, UserModel targetUser, RoomModel room) {
    final currentUserRole = room.getUserRole(currentUser.id);
    final targetUserRole = room.getUserRole(targetUser.id);
    
    // المالك يمكنه كتم الجميع
    if (currentUserRole == AppConstants.roleOwner) {
      return true;
    }
    
    // المدير يمكنه كتم المتحدثين والمستمعين فقط
    if (currentUserRole == AppConstants.roleAdmin) {
      return targetUserRole != AppConstants.roleOwner && 
             targetUserRole != AppConstants.roleAdmin;
    }
    
    return false;
  }

  // التحقق من إمكانية طرد المستخدم
  bool canKickUser(UserModel currentUser, UserModel targetUser, RoomModel room) {
    final currentUserRole = room.getUserRole(currentUser.id);
    final targetUserRole = room.getUserRole(targetUser.id);
    
    // فقط المالك يمكنه طرد المستخدمين
    if (currentUserRole == AppConstants.roleOwner) {
      return targetUser.id != currentUser.id; // لا يمكن طرد النفس
    }
    
    return false;
  }

  // التحقق من إمكانية تعيين مدير
  bool canAssignAdmin(UserModel currentUser, UserModel targetUser, RoomModel room) {
    final currentUserRole = room.getUserRole(currentUser.id);
    
    // فقط المالك يمكنه تعيين المدراء
    return currentUserRole == AppConstants.roleOwner && 
           targetUser.id != currentUser.id;
  }

  // التحقق من إمكانية تغيير عدد المايكات
  bool canChangeMicCount(UserModel user, RoomModel room) {
    final userRole = room.getUserRole(user.id);
    return userRole == AppConstants.roleOwner;
  }

  // التحقق من إمكانية الانتقال للمايك
  bool canRequestMic(UserModel user, RoomModel room) {
    // التحقق من عدم وجود المستخدم على مايك بالفعل
    final isAlreadyOnMic = room.seats.any((seat) => seat.userId == user.id);
    if (isAlreadyOnMic) return false;

    // التحقق من وجود مقاعد فارغة
    final hasEmptySeats = room.seats.any((seat) => seat.userId == null);
    if (hasEmptySeats) return true;

    // إذا لم توجد مقاعد فارغة، يمكن الانضمام لطابور الانتظار
    return true;
  }

  // التحقق من إمكانية مغادرة المايك
  bool canLeaveMic(UserModel user, RoomModel room) {
    return room.seats.any((seat) => seat.userId == user.id);
  }

  // التحقق من إمكانية إرسال رسائل
  bool canSendMessage(UserModel user, RoomModel room) {
    if (!room.settings.chatSettings.isEnabled) return false;
    
    if (room.settings.chatSettings.adminOnlyMode) {
      final userRole = room.getUserRole(user.id);
      return userRole == AppConstants.roleOwner || userRole == AppConstants.roleAdmin;
    }
    
    return true;
  }

  // الحصول على الإجراءات المتاحة للمستخدم
  List<UserAction> getAvailableActionsForUser(
    UserModel currentUser, 
    UserModel targetUser, 
    RoomModel room
  ) {
    List<UserAction> actions = [];
    
    // إجراءات المالك
    if (canKickUser(currentUser, targetUser, room)) {
      actions.add(UserAction(
        id: 'kick',
        title: 'طرد من الغرفة',
        icon: Icons.exit_to_app,
        color: Colors.red,
        isDestructive: true,
      ));
      
      actions.add(UserAction(
        id: 'ban',
        title: 'حظر المستخدم',
        icon: Icons.block,
        color: Colors.red[800]!,
        isDestructive: true,
      ));
    }
    
    if (canAssignAdmin(currentUser, targetUser, room)) {
      final targetRole = room.getUserRole(targetUser.id);
      if (targetRole == AppConstants.roleAdmin) {
        actions.add(UserAction(
          id: 'remove_admin',
          title: 'إزالة من الإدارة',
          icon: Icons.remove_moderator,
          color: Colors.orange,
        ));
      } else {
        actions.add(UserAction(
          id: 'assign_admin',
          title: 'تعيين كمدير',
          icon: Icons.admin_panel_settings,
          color: Colors.orange,
        ));
      }
    }
    
    // إجراءات المدير والمالك
    if (canMuteUser(currentUser, targetUser, room)) {
      final targetSeat = room.seats.firstWhere(
        (seat) => seat.userId == targetUser.id,
        orElse: () => room.seats.first,
      );
      
      if (targetSeat.userId == targetUser.id) {
        if (targetSeat.isMuted) {
          actions.add(UserAction(
            id: 'unmute',
            title: 'إلغاء الكتم',
            icon: Icons.mic,
            color: Colors.green,
          ));
        } else {
          actions.add(UserAction(
            id: 'mute',
            title: 'كتم المايك',
            icon: Icons.mic_off,
            color: Colors.red,
          ));
        }
        
        actions.add(UserAction(
          id: 'remove_from_mic',
          title: 'إنزال من المايك',
          icon: Icons.keyboard_arrow_down,
          color: Colors.orange,
        ));
      }
    }
    
    // إجراءات عامة
    actions.add(UserAction(
      id: 'view_profile',
      title: 'عرض الملف الشخصي',
      icon: Icons.person,
      color: Colors.blue,
    ));
    
    if (currentUser.id != targetUser.id) {
      actions.add(UserAction(
        id: 'send_message',
        title: 'إرسال رسالة خاصة',
        icon: Icons.message,
        color: Colors.blue,
      ));
    }
    
    return actions;
  }

  // تنفيذ الإجراء
  Future<bool> executeAction(
    String actionId,
    UserModel currentUser,
    UserModel targetUser,
    RoomModel room,
    BuildContext context,
  ) async {
    try {
      switch (actionId) {
        case 'kick':
          return await _kickUser(targetUser, room, context);
        case 'ban':
          return await _banUser(targetUser, room, context);
        case 'assign_admin':
          return await _assignAdmin(targetUser, room, context);
        case 'remove_admin':
          return await _removeAdmin(targetUser, room, context);
        case 'mute':
          return await _muteUser(targetUser, room, context);
        case 'unmute':
          return await _unmuteUser(targetUser, room, context);
        case 'remove_from_mic':
          return await _removeFromMic(targetUser, room, context);
        case 'view_profile':
          _viewProfile(targetUser, context);
          return true;
        case 'send_message':
          _sendPrivateMessage(targetUser, context);
          return true;
        default:
          return false;
      }
    } catch (error) {
      _showErrorDialog(context, 'فشل في تنفيذ العملية: $error');
      return false;
    }
  }

  // طرد المستخدم
  Future<bool> _kickUser(UserModel user, RoomModel room, BuildContext context) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'طرد المستخدم',
      'هل أنت متأكد من رغبتك في طرد ${user.displayName} من الغرفة؟',
    );
    
    if (!confirmed) return false;
    
    await _socketService.kickUser(room.roomId, user.id);
    _showSuccessSnackBar(context, 'تم طرد ${user.displayName} من الغرفة');
    return true;
  }

  // حظر المستخدم
  Future<bool> _banUser(UserModel user, RoomModel room, BuildContext context) async {
    final confirmed = await _showConfirmationDialog(
      context,
      'حظر المستخدم',
      'هل أنت متأكد من رغبتك في حظر ${user.displayName}؟ لن يتمكن من دخول الغرفة مرة أخرى.',
    );
    
    if (!confirmed) return false;
    
    await _socketService.banUser(room.roomId, user.id);
    _showSuccessSnackBar(context, 'تم حظر ${user.displayName}');
    return true;
  }

  // تعيين مدير
  Future<bool> _assignAdmin(UserModel user, RoomModel room, BuildContext context) async {
    await _socketService.assignAdmin(room.roomId, user.id);
    _showSuccessSnackBar(context, 'تم تعيين ${user.displayName} كمدير');
    return true;
  }

  // إزالة مدير
  Future<bool> _removeAdmin(UserModel user, RoomModel room, BuildContext context) async {
    await _socketService.removeAdmin(room.roomId, user.id);
    _showSuccessSnackBar(context, 'تم إزالة ${user.displayName} من الإدارة');
    return true;
  }

  // كتم المستخدم
  Future<bool> _muteUser(UserModel user, RoomModel room, BuildContext context) async {
    await _socketService.toggleUserMute(room.roomId, user.id, false);
    _showSuccessSnackBar(context, 'تم كتم ${user.displayName}');
    return true;
  }

  // إلغاء كتم المستخدم
  Future<bool> _unmuteUser(UserModel user, RoomModel room, BuildContext context) async {
    await _socketService.toggleUserMute(room.roomId, user.id, true);
    _showSuccessSnackBar(context, 'تم إلغاء كتم ${user.displayName}');
    return true;
  }

  // إنزال من المايك
  Future<bool> _removeFromMic(UserModel user, RoomModel room, BuildContext context) async {
    await _socketService.removeFromMic(room.roomId, user.id);
    _showSuccessSnackBar(context, 'تم إنزال ${user.displayName} من المايك');
    return true;
  }

  // عرض الملف الشخصي
  void _viewProfile(UserModel user, BuildContext context) {
    // TODO: تنفيذ عرض الملف الشخصي
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('الملف الشخصي'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: user.profilePicture != null
                  ? NetworkImage(user.profilePicture!)
                  : null,
              child: user.profilePicture == null
                  ? Icon(Icons.person, size: 40)
                  : null,
            ),
            SizedBox(height: 16),
            Text(
              user.displayName,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (user.bio != null) ...[
              SizedBox(height: 8),
              Text(user.bio!),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // إرسال رسالة خاصة
  void _sendPrivateMessage(UserModel user, BuildContext context) {
    // TODO: تنفيذ إرسال رسالة خاصة
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('رسالة خاصة'),
        content: Text('سيتم تنفيذ ميزة الرسائل الخاصة قريباً'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('موافق'),
          ),
        ],
      ),
    );
  }

  // عرض حوار التأكيد
  Future<bool> _showConfirmationDialog(
    BuildContext context,
    String title,
    String content,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('تأكيد'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }

  // عرض رسالة خطأ
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('خطأ'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('موافق'),
          ),
        ],
      ),
    );
  }

  // عرض رسالة نجاح
  void _showSuccessSnackBar(BuildContext context, String message) {
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
}

// نموذج الإجراء
class UserAction {
  final String id;
  final String title;
  final IconData icon;
  final Color color;
  final bool isDestructive;

  UserAction({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    this.isDestructive = false,
  });
}

