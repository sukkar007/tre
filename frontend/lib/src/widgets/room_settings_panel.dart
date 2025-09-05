import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/room_model.dart';
import '../models/user_model.dart';
import '../services/socket_service.dart';
import '../utils/app_constants.dart';

class RoomSettingsPanel extends StatefulWidget {
  final RoomModel? room;
  final UserModel currentUser;
  final VoidCallback onClose;

  const RoomSettingsPanel({
    Key? key,
    required this.room,
    required this.currentUser,
    required this.onClose,
  }) : super(key: key);

  @override
  State<RoomSettingsPanel> createState() => _RoomSettingsPanelState();
}

class _RoomSettingsPanelState extends State<RoomSettingsPanel>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  final SocketService _socketService = SocketService();
  
  // إعدادات محلية
  late bool chatEnabled;
  late bool profanityFilter;
  late bool slowMode;
  late int slowModeInterval;
  late bool adminOnlyChat;
  late bool youtubeEnabled;
  late bool musicEnabled;
  late double masterVolume;
  late double musicVolume;
  late int selectedMicCount;
  
  final List<int> micCountOptions = [2, 6, 12, 16, 20];
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeSettings();
  }

  void _initializeSettings() {
    if (widget.room != null) {
      final settings = widget.room!.settings;
      chatEnabled = settings.chatSettings.isEnabled;
      profanityFilter = settings.chatSettings.profanityFilterEnabled;
      slowMode = settings.chatSettings.slowModeEnabled;
      slowModeInterval = settings.chatSettings.slowModeInterval;
      adminOnlyChat = settings.chatSettings.adminOnlyMode;
      youtubeEnabled = settings.mediaSettings.youtubeEnabled;
      musicEnabled = settings.mediaSettings.musicEnabled;
      masterVolume = settings.mediaSettings.masterVolume;
      musicVolume = settings.mediaSettings.musicVolume;
      selectedMicCount = widget.room!.micCount;
    } else {
      // قيم افتراضية
      chatEnabled = true;
      profanityFilter = true;
      slowMode = false;
      slowModeInterval = 5;
      adminOnlyChat = false;
      youtubeEnabled = false;
      musicEnabled = false;
      masterVolume = 1.0;
      musicVolume = 0.7;
      selectedMicCount = 6;
    }
  }

  Future<void> _updateChatSettings() async {
    if (widget.room == null || isUpdating) return;

    setState(() {
      isUpdating = true;
    });

    try {
      await _socketService.updateChatSettings(widget.room!.roomId, {
        'isEnabled': chatEnabled,
        'profanityFilterEnabled': profanityFilter,
        'slowModeEnabled': slowMode,
        'slowModeInterval': slowModeInterval,
        'adminOnlyMode': adminOnlyChat,
      });

      _showSuccessSnackBar('تم تحديث إعدادات الدردشة');
    } catch (error) {
      _showErrorSnackBar('فشل في تحديث إعدادات الدردشة: $error');
    } finally {
      setState(() {
        isUpdating = false;
      });
    }
  }

  Future<void> _updateMediaSettings() async {
    if (widget.room == null || isUpdating) return;

    setState(() {
      isUpdating = true;
    });

    try {
      await _socketService.updateMediaSettings(widget.room!.roomId, {
        'youtubeEnabled': youtubeEnabled,
        'musicEnabled': musicEnabled,
        'masterVolume': masterVolume,
        'musicVolume': musicVolume,
      });

      _showSuccessSnackBar('تم تحديث إعدادات الوسائط');
    } catch (error) {
      _showErrorSnackBar('فشل في تحديث إعدادات الوسائط: $error');
    } finally {
      setState(() {
        isUpdating = false;
      });
    }
  }

  Future<void> _changeMicCount(int newCount) async {
    if (widget.room == null || isUpdating || newCount == selectedMicCount) return;

    setState(() {
      isUpdating = true;
    });

    try {
      await _socketService.changeMicCount(widget.room!.roomId, newCount);
      
      setState(() {
        selectedMicCount = newCount;
      });

      HapticFeedback.mediumImpact();
      _showSuccessSnackBar('تم تغيير عدد المايكات إلى $newCount');
    } catch (error) {
      _showErrorSnackBar('فشل في تغيير عدد المايكات: $error');
    } finally {
      setState(() {
        isUpdating = false;
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

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppConstants.primaryColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        children: [
          Icon(Icons.settings, color: Colors.white, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'إعدادات الغرفة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onClose,
            icon: Icon(Icons.close, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              shape: CircleBorder(),
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
        labelColor: AppConstants.primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppConstants.primaryColor,
        tabs: [
          Tab(icon: Icon(Icons.mic), text: 'المايكات'),
          Tab(icon: Icon(Icons.chat), text: 'الدردشة'),
          Tab(icon: Icon(Icons.music_note), text: 'الوسائط'),
          Tab(icon: Icon(Icons.people), text: 'المستخدمين'),
        ],
      ),
    );
  }

  Widget _buildMicSettings() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'عدد المايكات',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),
          
          // معاينة التخطيط
          Container(
            height: 120,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Center(
              child: _buildMicLayoutPreview(selectedMicCount),
            ),
          ),
          
          SizedBox(height: 20),
          
          // خيارات عدد المايكات
          Text(
            'اختر عدد المايكات:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 12),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: micCountOptions.map((count) {
              final isSelected = count == selectedMicCount;
              return GestureDetector(
                onTap: () => _changeMicCount(count),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isSelected ? AppConstants.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppConstants.primaryColor : Colors.grey[300]!,
                      width: 2,
                    ),
                    boxShadow: isSelected ? [
                      BoxShadow(
                        color: AppConstants.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ] : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$count',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'مايك',
                        style: TextStyle(
                          fontSize: 10,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          
          SizedBox(height: 20),
          
          if (isUpdating)
            Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  Widget _buildMicLayoutPreview(int count) {
    List<Widget> mics = [];
    
    for (int i = 0; i < count; i++) {
      mics.add(
        Container(
          width: 20,
          height: 20,
          margin: EdgeInsets.all(2),
          decoration: BoxDecoration(
            color: i == 0 ? Colors.amber : AppConstants.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            i == 0 ? Icons.star : Icons.mic,
            size: 12,
            color: Colors.white,
          ),
        ),
      );
    }
    
    return Wrap(
      alignment: WrapAlignment.center,
      children: mics,
    );
  }

  Widget _buildChatSettings() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.chat,
            title: 'تفعيل الدردشة',
            subtitle: 'السماح للمستخدمين بإرسال الرسائل',
            value: chatEnabled,
            onChanged: (value) {
              setState(() {
                chatEnabled = value;
              });
              _updateChatSettings();
            },
          ),
          
          _buildSettingTile(
            icon: Icons.filter_alt,
            title: 'فلتر الكلمات السيئة',
            subtitle: 'حذف الرسائل التي تحتوي على كلمات غير مناسبة',
            value: profanityFilter,
            onChanged: chatEnabled ? (value) {
              setState(() {
                profanityFilter = value;
              });
              _updateChatSettings();
            } : null,
          ),
          
          _buildSettingTile(
            icon: Icons.speed,
            title: 'الوضع البطيء',
            subtitle: 'تحديد فترة انتظار بين الرسائل',
            value: slowMode,
            onChanged: chatEnabled ? (value) {
              setState(() {
                slowMode = value;
              });
              _updateChatSettings();
            } : null,
          ),
          
          if (slowMode && chatEnabled)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text('فترة الانتظار:'),
                  Expanded(
                    child: Slider(
                      value: slowModeInterval.toDouble(),
                      min: 1,
                      max: 60,
                      divisions: 59,
                      label: '$slowModeInterval ثانية',
                      onChanged: (value) {
                        setState(() {
                          slowModeInterval = value.round();
                        });
                      },
                      onChangeEnd: (value) {
                        _updateChatSettings();
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          _buildSettingTile(
            icon: Icons.admin_panel_settings,
            title: 'دردشة المدراء فقط',
            subtitle: 'السماح للمدراء والمالك فقط بالكتابة',
            value: adminOnlyChat,
            onChanged: chatEnabled ? (value) {
              setState(() {
                adminOnlyChat = value;
              });
              _updateChatSettings();
            } : null,
          ),
        ],
      ),
    );
  }

  Widget _buildMediaSettings() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildSettingTile(
            icon: Icons.video_library,
            title: 'تفعيل اليوتيوب',
            subtitle: 'السماح بتشغيل فيديوهات اليوتيوب',
            value: youtubeEnabled,
            onChanged: (value) {
              setState(() {
                youtubeEnabled = value;
              });
              _updateMediaSettings();
            },
          ),
          
          _buildSettingTile(
            icon: Icons.music_note,
            title: 'تفعيل الموسيقى',
            subtitle: 'السماح بتشغيل الملفات الصوتية',
            value: musicEnabled,
            onChanged: (value) {
              setState(() {
                musicEnabled = value;
              });
              _updateMediaSettings();
            },
          ),
          
          SizedBox(height: 20),
          
          _buildVolumeSlider(
            title: 'مستوى الصوت الرئيسي',
            value: masterVolume,
            onChanged: (value) {
              setState(() {
                masterVolume = value;
              });
            },
            onChangeEnd: (value) {
              _updateMediaSettings();
            },
          ),
          
          if (musicEnabled)
            _buildVolumeSlider(
              title: 'مستوى صوت الموسيقى',
              value: musicVolume,
              onChanged: (value) {
                setState(() {
                  musicVolume = value;
                });
              },
              onChangeEnd: (value) {
                _updateMediaSettings();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildUserManagement() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          _buildManagementButton(
            icon: Icons.admin_panel_settings,
            title: 'إدارة المدراء',
            subtitle: 'تعيين وإزالة المدراء',
            color: Colors.orange,
            onTap: () {
              // TODO: إظهار قائمة المدراء
            },
          ),
          
          _buildManagementButton(
            icon: Icons.block,
            title: 'قائمة المحظورين',
            subtitle: 'إدارة المستخدمين المحظورين',
            color: Colors.red,
            onTap: () {
              // TODO: إظهار قائمة المحظورين
            },
          ),
          
          _buildManagementButton(
            icon: Icons.queue,
            title: 'طابور الانتظار',
            subtitle: 'إدارة طلبات الانتقال للمايك',
            color: Colors.blue,
            onTap: () {
              // TODO: إظهار طابور الانتظار
            },
          ),
          
          _buildManagementButton(
            icon: Icons.people,
            title: 'قائمة المستخدمين',
            subtitle: 'عرض جميع المستخدمين المتصلين',
            color: Colors.green,
            onTap: () {
              // TODO: إظهار قائمة المستخدمين
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppConstants.primaryColor),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: Switch(
          value: value,
          onChanged: onChanged,
          activeColor: AppConstants.primaryColor,
        ),
      ),
    );
  }

  Widget _buildVolumeSlider({
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Icon(Icons.volume_down),
                Expanded(
                  child: Slider(
                    value: value,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    label: '${(value * 100).round()}%',
                    onChanged: onChanged,
                    onChangeEnd: onChangeEnd,
                  ),
                ),
                Icon(Icons.volume_up),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.horizontal(left: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(-5, 0),
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
                _buildMicSettings(),
                _buildChatSettings(),
                _buildMediaSettings(),
                _buildUserManagement(),
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

