import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../services/socket_service.dart';
import '../utils/app_constants.dart';

class RoomInviteWidget extends StatefulWidget {
  final RoomModel room;
  final UserModel currentUser;

  const RoomInviteWidget({
    Key? key,
    required this.room,
    required this.currentUser,
  }) : super(key: key);

  @override
  State<RoomInviteWidget> createState() => _RoomInviteWidgetState();
}

class _RoomInviteWidgetState extends State<RoomInviteWidget>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  final SocketService _socketService = SocketService();
  
  String? roomLink;
  bool isGeneratingLink = false;
  List<UserModel> friends = [];
  List<UserModel> selectedFriends = [];
  bool isLoadingFriends = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _generateRoomLink();
    _loadFriends();
  }

  Future<void> _generateRoomLink() async {
    setState(() {
      isGeneratingLink = true;
    });

    try {
      // TODO: استدعاء API لإنشاء رابط الغرفة
      await Future.delayed(Duration(seconds: 1)); // محاكاة
      setState(() {
        roomLink = 'https://husapp.com/room/${widget.room.roomId}';
      });
    } catch (error) {
      _showErrorSnackBar('فشل في إنشاء رابط الغرفة');
    } finally {
      setState(() {
        isGeneratingLink = false;
      });
    }
  }

  Future<void> _loadFriends() async {
    setState(() {
      isLoadingFriends = true;
    });

    try {
      // TODO: استدعاء API لجلب قائمة الأصدقاء
      await Future.delayed(Duration(seconds: 1)); // محاكاة
      setState(() {
        friends = [
          // بيانات تجريبية
          UserModel(
            userId: '1',
            displayName: 'أحمد محمد',
            email: 'friend1@example.com',
            photoURL: null,
            isOnline: true,
            isVip: false,
          ),
          UserModel(
            userId: '2',
            displayName: 'فاطمة علي',
            email: 'friend2@example.com',
            photoURL: null,
            isOnline: true,
            isVip: false,
          ),
          UserModel(
            userId: '3',
            displayName: 'محمد أحمد',
            email: 'friend3@example.com',
            photoURL: null,
            isOnline: false,
            isVip: false,
          ),
        ];
      });
    } catch (error) {
      _showErrorSnackBar('فشل في تحميل قائمة الأصدقاء');
    } finally {
      setState(() {
        isLoadingFriends = false;
      });
    }
  }

  Future<void> _shareRoomLink() async {
    if (roomLink == null) return;

    try {
      HapticFeedback.lightImpact();
      
      final shareText = '''
🎤 انضم إلي في غرفة "${widget.room.title}"

${widget.room.description ?? 'غرفة دردشة صوتية ممتعة'}

الرابط: $roomLink

تطبيق HUS - أفضل تطبيق للدردشة الصوتية
      '''.trim();

      await Share.share(
        shareText,
        subject: 'دعوة للانضمام إلى غرفة ${widget.room.title}',
      );
    } catch (error) {
      _showErrorSnackBar('فشل في مشاركة الرابط');
    }
  }

  Future<void> _copyRoomLink() async {
    if (roomLink == null) return;

    try {
      HapticFeedback.lightImpact();
      await Clipboard.setData(ClipboardData(text: roomLink!));
      _showSuccessSnackBar('تم نسخ الرابط');
    } catch (error) {
      _showErrorSnackBar('فشل في نسخ الرابط');
    }
  }

  Future<void> _sendFriendInvites() async {
    if (selectedFriends.isEmpty) return;

    try {
      HapticFeedback.mediumImpact();
      
      for (final friend in selectedFriends) {
        await _socketService.sendRoomInvite(
          widget.room.roomId,
          friend.id,
          'انضم إلي في غرفة "${widget.room.title}"',
        );
      }

      _showSuccessSnackBar('تم إرسال ${selectedFriends.length} دعوة');
      setState(() {
        selectedFriends.clear();
      });
    } catch (error) {
      _showErrorSnackBar('فشل في إرسال الدعوات');
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

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(AppConstants.primaryColorValue),
            Color(AppConstants.primaryColorValue).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // مؤشر السحب
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(height: 20),
          
          Row(
            children: [
              Icon(Icons.share, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'دعوة أصدقاء',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: Colors.white),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  shape: CircleBorder(),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 16),
          
          // معلومات الغرفة
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.mic,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.room.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (widget.room.description != null)
                        Text(
                          widget.room.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                Text(
                  '${widget.room.currentParticipants}/${widget.room.maxParticipants}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: Color(AppConstants.primaryColorValue),
        unselectedLabelColor: Colors.grey,
        indicatorColor: Color(AppConstants.primaryColorValue),
        tabs: [
          Tab(icon: Icon(Icons.link), text: 'رابط'),
          Tab(icon: Icon(Icons.people), text: 'أصدقاء'),
          Tab(icon: Icon(Icons.qr_code), text: 'QR'),
        ],
      ),
    );
  }

  Widget _buildLinkTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // رابط الغرفة
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'رابط الغرفة',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                if (isGeneratingLink)
                  Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 8),
                      Text('جاري إنشاء الرابط...'),
                    ],
                  )
                else if (roomLink != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            roomLink!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(AppConstants.primaryColorValue),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _copyRoomLink,
                          icon: Icon(Icons.copy, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: Color(AppConstants.primaryColorValue).withOpacity(0.1),
                            shape: CircleBorder(),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          SizedBox(height: 20),
          
          // أزرار المشاركة
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: roomLink != null ? _shareRoomLink : null,
                  icon: Icon(Icons.share),
                  label: Text('مشاركة'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(AppConstants.primaryColorValue),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: roomLink != null ? _copyRoomLink : null,
                  icon: Icon(Icons.copy),
                  label: Text('نسخ'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Color(AppConstants.primaryColorValue),
                    side: BorderSide(color: Color(AppConstants.primaryColorValue)),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          SizedBox(height: 20),
          
          // معلومات إضافية
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'يمكن لأي شخص لديه هذا الرابط الانضمام إلى الغرفة',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Column(
      children: [
        // شريط البحث
        Container(
          padding: EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'البحث عن أصدقاء...',
              prefixIcon: Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Color(AppConstants.primaryColorValue)),
              ),
            ),
            onChanged: (value) {
              // TODO: تنفيذ البحث
            },
          ),
        ),
        
        // قائمة الأصدقاء
        Expanded(
          child: isLoadingFriends
              ? Center(child: CircularProgressIndicator())
              : friends.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'لا توجد أصدقاء',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      itemCount: friends.length,
                      separatorBuilder: (context, index) => SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        final isSelected = selectedFriends.contains(friend);
                        
                        return Container(
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? Color(AppConstants.primaryColorValue).withOpacity(0.1)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected 
                                  ? Color(AppConstants.primaryColorValue).withOpacity(0.3)
                                  : Colors.grey[300]!,
                            ),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage: friend.profilePicture != null
                                  ? NetworkImage(friend.profilePicture!)
                                  : null,
                              child: friend.profilePicture == null
                                  ? Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(friend.displayName),
                            trailing: Checkbox(
                              value: isSelected,
                              onChanged: (value) {
                                setState(() {
                                  if (value == true) {
                                    selectedFriends.add(friend);
                                  } else {
                                    selectedFriends.remove(friend);
                                  }
                                });
                              },
                              activeColor: Color(AppConstants.primaryColorValue),
                            ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedFriends.remove(friend);
                                } else {
                                  selectedFriends.add(friend);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
        ),
        
        // زر الإرسال
        if (selectedFriends.isNotEmpty)
          Container(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sendFriendInvites,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(AppConstants.primaryColorValue),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'إرسال دعوة (${selectedFriends.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildQRTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          Text(
            'رمز QR للغرفة',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          
          if (roomLink != null)
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: QrImageView(
                data: roomLink!,
                version: QrVersions.auto,
                size: 200.0,
                backgroundColor: Colors.white,
              ),
            )
          else
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          
          SizedBox(height: 20),
          
          Text(
            'اطلب من أصدقائك مسح هذا الرمز للانضمام إلى الغرفة',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 20),
          
          ElevatedButton.icon(
            onPressed: roomLink != null ? _shareRoomLink : null,
            icon: Icon(Icons.share),
            label: Text('مشاركة رمز QR'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(AppConstants.primaryColorValue),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
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
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildLinkTab(),
                _buildFriendsTab(),
                _buildQRTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}

// Helper function لعرض نافذة الدعوات
void showRoomInviteSheet(
  BuildContext context,
  RoomModel room,
  UserModel currentUser,
) {
  HapticFeedback.lightImpact();
  
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => RoomInviteWidget(
      room: room,
      currentUser: currentUser,
    ),
  );
}

