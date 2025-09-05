import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/media_service.dart';
import '../models/media_content_model.dart';
import 'youtube_player_widget.dart';

/// لوحة التحكم في الوسائط
class MediaControlPanel extends StatefulWidget {
  final bool isRoomOwner;
  final VoidCallback? onTogglePanel;

  const MediaControlPanel({
    Key? key,
    required this.isRoomOwner,
    this.onTogglePanel,
  }) : super(key: key);

  @override
  State<MediaControlPanel> createState() => _MediaControlPanelState();
}

class _MediaControlPanelState extends State<MediaControlPanel>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _youtubeUrlController = TextEditingController();
  bool _isExpanded = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _youtubeUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaService>(
      builder: (context, mediaService, child) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // مقبض السحب
              _buildDragHandle(),
              
              // مشغل الوسائط الحالي
              if (mediaService.currentContent != null)
                _buildCurrentMediaPlayer(mediaService),
              
              // أدوات التحكم السريعة
              _buildQuickControls(mediaService),
              
              // المحتوى القابل للتوسيع
              if (_isExpanded) ...[
                const Divider(),
                _buildExpandedContent(mediaService),
              ],
            ],
          ),
        );
      },
    );
  }

  /// بناء مقبض السحب
  Widget _buildDragHandle() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isExpanded = !_isExpanded;
        });
        widget.onTogglePanel?.call();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[400],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }

  /// بناء مشغل الوسائط الحالي
  Widget _buildCurrentMediaPlayer(MediaService mediaService) {
    final content = mediaService.currentContent!;
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // مشغل YouTube
          if (content.type == 'youtube')
            SizedBox(
              height: 200,
              child: YouTubePlayerWidget(
                showControls: true,
                allowFullScreen: true,
              ),
            ),
          
          // مشغل الصوت
          if (content.type == 'audio_file')
            _buildAudioPlayer(mediaService, content),
        ],
      ),
    );
  }

  /// بناء مشغل الصوت
  Widget _buildAudioPlayer(MediaService mediaService, MediaContent content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // معلومات الملف الصوتي
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.music_note,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      content.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content.audioData?.fileName ?? 'ملف صوتي',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // شريط التقدم
          Column(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Theme.of(context).primaryColor,
                  inactiveTrackColor: Colors.grey[300],
                  thumbColor: Theme.of(context).primaryColor,
                  overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
                ),
                child: Slider(
                  value: mediaService.currentPosition.clamp(0.0, mediaService.duration),
                  max: mediaService.duration > 0 ? mediaService.duration : 1.0,
                  onChanged: (value) {
                    // تحديث محلي فوري
                  },
                  onChangeEnd: (value) {
                    mediaService.seekTo(value);
                  },
                ),
              ),
              
              // أوقات التشغيل
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(Duration(seconds: mediaService.currentPosition.toInt())),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      _formatDuration(Duration(seconds: mediaService.duration.toInt())),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // أزرار التحكم
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () {
                  final newPosition = (mediaService.currentPosition - 10).clamp(0.0, mediaService.duration);
                  mediaService.seekTo(newPosition);
                },
                icon: const Icon(Icons.replay_10),
              ),
              
              const SizedBox(width: 20),
              
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () {
                    if (mediaService.isPlaying) {
                      mediaService.pauseContent();
                    } else {
                      mediaService.startContent(
                        content.contentId,
                        startPosition: mediaService.currentPosition,
                      );
                    }
                  },
                  icon: Icon(
                    mediaService.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
              ),
              
              const SizedBox(width: 20),
              
              IconButton(
                onPressed: () {
                  final newPosition = (mediaService.currentPosition + 10).clamp(0.0, mediaService.duration);
                  mediaService.seekTo(newPosition);
                },
                icon: const Icon(Icons.forward_10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء أدوات التحكم السريعة
  Widget _buildQuickControls(MediaService mediaService) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // زر إضافة محتوى
          if (widget.isRoomOwner)
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _showAddContentDialog(),
                icon: const Icon(Icons.add),
                label: const Text('إضافة محتوى'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          
          if (widget.isRoomOwner) const SizedBox(width: 12),
          
          // زر قائمة التشغيل
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => _showPlaylistDialog(mediaService),
              icon: const Icon(Icons.queue_music),
              label: Text('القائمة (${mediaService.roomPlaylist.length})'),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // زر الإعدادات
          IconButton(
            onPressed: () => _showMediaSettings(mediaService),
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
    );
  }

  /// بناء المحتوى القابل للتوسيع
  Widget _buildExpandedContent(MediaService mediaService) {
    return SizedBox(
      height: 300,
      child: TabBarView(
        controller: _tabController,
        children: [
          // قائمة التشغيل
          _buildPlaylistTab(mediaService),
          
          // إضافة محتوى
          if (widget.isRoomOwner) _buildAddContentTab(),
          
          // الإعدادات
          _buildSettingsTab(mediaService),
        ],
      ),
    );
  }

  /// تبويب قائمة التشغيل
  Widget _buildPlaylistTab(MediaService mediaService) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: mediaService.roomPlaylist.length,
      itemBuilder: (context, index) {
        final content = mediaService.roomPlaylist[index];
        final isActive = content.contentId == mediaService.currentContent?.contentId;
        
        return Card(
          color: isActive ? Theme.of(context).primaryColor.withOpacity(0.1) : null,
          child: ListTile(
            leading: _buildContentIcon(content),
            title: Text(
              content.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _getContentSubtitle(content),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isActive)
                  Icon(
                    Icons.play_circle,
                    color: Theme.of(context).primaryColor,
                  ),
                
                if (widget.isRoomOwner)
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'play',
                        child: ListTile(
                          leading: Icon(Icons.play_arrow),
                          title: Text('تشغيل'),
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete, color: Colors.red),
                          title: Text('حذف'),
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'play') {
                        mediaService.startContent(content.contentId);
                      } else if (value == 'delete') {
                        _confirmDeleteContent(content, mediaService);
                      }
                    },
                  ),
              ],
            ),
            onTap: () {
              if (!isActive) {
                mediaService.startContent(content.contentId);
              }
            },
          ),
        );
      },
    );
  }

  /// تبويب إضافة محتوى
  Widget _buildAddContentTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // إضافة YouTube
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إضافة فيديو YouTube',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _youtubeUrlController,
                    decoration: const InputDecoration(
                      hintText: 'أدخل رابط YouTube',
                      prefixIcon: Icon(Icons.link),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addYouTubeVideo,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('إضافة'),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // إضافة ملف صوتي
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إضافة ملف صوتي',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _addAudioFile,
                      icon: const Icon(Icons.audio_file),
                      label: const Text('اختيار ملف'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// تبويب الإعدادات
  Widget _buildSettingsTab(MediaService mediaService) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // مستوى الصوت
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'مستوى الصوت',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Slider(
                    value: mediaService.volume,
                    onChanged: (value) {
                      mediaService.changeVolume(value * 100);
                    },
                  ),
                  Text('${(mediaService.volume * 100).round()}%'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // إعدادات التشغيل
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'إعدادات التشغيل',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // زر إيقاف جميع المحتوى
                  if (widget.isRoomOwner)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => mediaService.stopContent(),
                        icon: const Icon(Icons.stop),
                        label: const Text('إيقاف جميع المحتوى'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// بناء أيقونة المحتوى
  Widget _buildContentIcon(MediaContent content) {
    IconData icon;
    Color color;
    
    switch (content.type) {
      case 'youtube':
        icon = Icons.play_circle;
        color = Colors.red;
        break;
      case 'audio_file':
        icon = Icons.music_note;
        color = Colors.blue;
        break;
      default:
        icon = Icons.library_music;
        color = Colors.grey;
    }
    
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color),
    );
  }

  /// الحصول على العنوان الفرعي للمحتوى
  String _getContentSubtitle(MediaContent content) {
    switch (content.type) {
      case 'youtube':
        return content.youtubeData?.channelName ?? 'YouTube';
      case 'audio_file':
        return content.audioData?.fileName ?? 'ملف صوتي';
      default:
        return content.type;
    }
  }

  /// إضافة فيديو YouTube
  Future<void> _addYouTubeVideo() async {
    if (_youtubeUrlController.text.trim().isEmpty) {
      _showErrorSnackBar('يرجى إدخال رابط YouTube');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final mediaService = Provider.of<MediaService>(context, listen: false);
      final success = await mediaService.addYouTubeVideo(_youtubeUrlController.text.trim());
      
      if (success) {
        _youtubeUrlController.clear();
        _showSuccessSnackBar('تم إضافة الفيديو بنجاح');
      } else {
        _showErrorSnackBar('فشل في إضافة الفيديو');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// إضافة ملف صوتي
  Future<void> _addAudioFile() async {
    try {
      final mediaService = Provider.of<MediaService>(context, listen: false);
      final success = await mediaService.addAudioFile();
      
      if (success) {
        _showSuccessSnackBar('تم إضافة الملف الصوتي بنجاح');
      } else {
        _showErrorSnackBar('فشل في إضافة الملف الصوتي');
      }
    } catch (e) {
      _showErrorSnackBar('خطأ: $e');
    }
  }

  /// تأكيد حذف المحتوى
  void _confirmDeleteContent(MediaContent content, MediaService mediaService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text('هل تريد حذف "${content.title}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              mediaService.deleteContent(content.contentId);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// عرض حوار إضافة المحتوى
  void _showAddContentDialog() {
    setState(() {
      _isExpanded = true;
    });
    _tabController.animateTo(1);
  }

  /// عرض حوار قائمة التشغيل
  void _showPlaylistDialog(MediaService mediaService) {
    setState(() {
      _isExpanded = true;
    });
    _tabController.animateTo(0);
  }

  /// عرض إعدادات الوسائط
  void _showMediaSettings(MediaService mediaService) {
    setState(() {
      _isExpanded = true;
    });
    _tabController.animateTo(2);
  }

  /// عرض رسالة خطأ
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// عرض رسالة نجاح
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// تنسيق المدة الزمنية
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${twoDigits(minutes)}:${twoDigits(seconds)}';
  }
}

