import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import '../models/user_model.dart';
import '../models/room_message_model.dart';
import '../services/socket_service.dart';
import '../utils/app_constants.dart';

class RoomChatWidget extends StatefulWidget {
  final String roomId;
  final UserModel currentUser;

  const RoomChatWidget({
    Key? key,
    required this.roomId,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<RoomChatWidget> createState() => _RoomChatWidgetState();
}

class _RoomChatWidgetState extends State<RoomChatWidget>
    with TickerProviderStateMixin {
  
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _messageFocusNode = FocusNode();
  
  List<RoomMessageModel> messages = [];
  bool isTyping = false;
  bool isChatEnabled = true;
  RoomMessageModel? replyingTo;
  
  late AnimationController _newMessageController;
  late Animation<double> _newMessageAnimation;
  
  final SocketService _socketService = SocketService();
  StreamSubscription? _messageSubscription;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _setupMessageListener();
    _loadInitialMessages();
  }
  
  void _initializeAnimations() {
    _newMessageController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _newMessageAnimation = CurvedAnimation(
      parent: _newMessageController,
      curve: Curves.easeOutBack,
    );
  }
  
  void _setupMessageListener() {
    _messageSubscription = _socketService.onNewMessage.listen((data) {
      final message = RoomMessageModel.fromJson(data['message']);
      setState(() {
        messages.add(message);
      });
      
      _newMessageController.forward().then((_) {
        _newMessageController.reset();
      });
      
      _scrollToBottom();
      
      // اهتزاز خفيف للرسائل الجديدة
      if (message.senderId != widget.currentUser.id) {
        HapticFeedback.lightImpact();
      }
    });
  }
  
  Future<void> _loadInitialMessages() async {
    // TODO: تحميل الرسائل السابقة من API
    // هنا يمكن إضافة رسائل تجريبية
    setState(() {
      messages = [
        RoomMessageModel.createSystemMessage(
          roomId: widget.roomId,
          content: 'مرحباً بكم في الغرفة الصوتية!',
          messageType: 'welcome',
        ),
      ];
    });
  }
  
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || !isChatEnabled) return;
    
    try {
      await _socketService.sendMessage(
        widget.roomId,
        messageText,
        replyTo: replyingTo?.id,
      );
      
      _messageController.clear();
      setState(() {
        replyingTo = null;
      });
      
      HapticFeedback.lightImpact();
      
    } catch (error) {
      _showErrorSnackBar('فشل في إرسال الرسالة: $error');
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
  
  Widget _buildMessageItem(RoomMessageModel message, int index) {
    final isCurrentUser = message.senderId == widget.currentUser.id;
    final isSystemMessage = message.messageType == 'system';
    
    if (isSystemMessage) {
      return _buildSystemMessage(message);
    }
    
    return AnimatedBuilder(
      animation: _newMessageAnimation,
      builder: (context, child) {
        final isNewMessage = index == messages.length - 1;
        return Transform.scale(
          scale: isNewMessage ? _newMessageAnimation.value : 1.0,
          child: _buildUserMessage(message, isCurrentUser),
        );
      },
    );
  }
  
  Widget _buildSystemMessage(RoomMessageModel message) {
    IconData icon;
    Color color;
    
    switch (message.messageType) {
      case 'user_joined':
        icon = Icons.login;
        color = Colors.green;
        break;
      case 'user_left':
        icon = Icons.logout;
        color = Colors.orange;
        break;
      case 'mic_change':
        icon = Icons.mic;
        color = Colors.blue;
        break;
      case 'admin_action':
        icon = Icons.admin_panel_settings;
        color = Colors.purple;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }
    
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.senderProfilePicture != null) ...[
                  CircleAvatar(
                    radius: 10,
                    backgroundImage: NetworkImage(message.senderProfilePicture!),
                  ),
                  SizedBox(width: 6),
                ],
                Icon(icon, size: 14, color: color),
                SizedBox(width: 6),
                Text(
                  message.content,
                  style: TextStyle(
                    fontSize: 12,
                    color: color,
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
  
  Widget _buildUserMessage(RoomMessageModel message, bool isCurrentUser) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 2, horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCurrentUser) ...[
            // صورة المرسل
            CircleAvatar(
              radius: 16,
              backgroundColor: _getSenderColor(message.senderRole),
              backgroundImage: message.senderProfilePicture != null
                  ? NetworkImage(message.senderProfilePicture!)
                  : null,
              child: message.senderProfilePicture == null
                  ? Icon(Icons.person, size: 18, color: Colors.white)
                  : null,
            ),
            SizedBox(width: 8),
          ],
          
          // محتوى الرسالة
          Expanded(
            child: Column(
              crossAxisAlignment: isCurrentUser 
                  ? CrossAxisAlignment.end 
                  : CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  Padding(
                    padding: EdgeInsets.only(bottom: 2),
                    child: Row(
                      children: [
                        Text(
                          message.senderName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: _getSenderColor(message.senderRole),
                          ),
                        ),
                        if (message.senderRole == 'owner') ...[
                          SizedBox(width: 4),
                          Icon(Icons.crown, size: 12, color: Colors.purple),
                        ] else if (message.senderRole == 'admin') ...[
                          SizedBox(width: 4),
                          Icon(Icons.admin_panel_settings, size: 12, color: Colors.orange),
                        ],
                      ],
                    ),
                  ),
                
                // الرد على رسالة
                if (message.replyTo != null)
                  _buildReplyPreview(message.replyTo!),
                
                // محتوى الرسالة
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isCurrentUser 
                        ? AppConstants.primaryColor 
                        : Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    message.content,
                    style: TextStyle(
                      fontSize: 14,
                      color: isCurrentUser ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                
                // وقت الإرسال
                Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Text(
                    _formatMessageTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          if (isCurrentUser) ...[
            SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppConstants.primaryColor,
              backgroundImage: widget.currentUser.profilePicture != null
                  ? NetworkImage(widget.currentUser.profilePicture!)
                  : null,
              child: widget.currentUser.profilePicture == null
                  ? Icon(Icons.person, size: 18, color: Colors.white)
                  : null,
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildReplyPreview(RoomMessageModel replyMessage) {
    return Container(
      margin: EdgeInsets.only(bottom: 4),
      padding: EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border(
          right: BorderSide(color: AppConstants.primaryColor, width: 3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            replyMessage.senderName,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _getSenderColor(replyMessage.senderRole),
            ),
          ),
          Text(
            replyMessage.content,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[600],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
  
  Color _getSenderColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.purple;
      case 'admin':
        return Colors.orange;
      case 'speaker':
        return Colors.blue;
      default:
        return Colors.grey[700]!;
    }
  }
  
  String _formatMessageTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'الآن';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}د';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}س';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
  
  Widget _buildReplyBar() {
    if (replyingTo == null) return SizedBox.shrink();
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, size: 16, color: AppConstants.primaryColor),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'الرد على ${replyingTo!.senderName}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppConstants.primaryColor,
                  ),
                ),
                Text(
                  replyingTo!.content,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                replyingTo = null;
              });
            },
            icon: Icon(Icons.close, size: 18),
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                focusNode: _messageFocusNode,
                enabled: isChatEnabled,
                decoration: InputDecoration(
                  hintText: isChatEnabled 
                      ? 'اكتب رسالة...' 
                      : 'الدردشة معطلة',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: null,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                onChanged: (text) {
                  setState(() {
                    isTyping = text.isNotEmpty;
                  });
                },
              ),
            ),
          ),
          SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              color: isTyping && isChatEnabled 
                  ? AppConstants.primaryColor 
                  : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: isTyping && isChatEnabled ? _sendMessage : null,
              icon: Icon(
                Icons.send,
                color: isTyping && isChatEnabled 
                    ? Colors.white 
                    : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // شريط عنوان الدردشة
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              bottom: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.chat, size: 18, color: AppConstants.primaryColor),
              SizedBox(width: 8),
              Text(
                'الدردشة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              if (!isChatEnabled)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'معطلة',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // شريط الرد
        _buildReplyBar(),
        
        // قائمة الرسائل
        Expanded(
          child: messages.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد رسائل بعد',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        'كن أول من يبدأ المحادثة!',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      onLongPress: () {
                        if (messages[index].messageType != 'system') {
                          setState(() {
                            replyingTo = messages[index];
                          });
                          _messageFocusNode.requestFocus();
                        }
                      },
                      child: _buildMessageItem(messages[index], index),
                    );
                  },
                ),
        ),
        
        // حقل إدخال الرسالة
        _buildMessageInput(),
      ],
    );
  }
  
  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageFocusNode.dispose();
    _newMessageController.dispose();
    _messageSubscription?.cancel();
    super.dispose();
  }
}

