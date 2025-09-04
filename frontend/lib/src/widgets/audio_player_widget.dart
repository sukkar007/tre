import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/media_service.dart';
import '../models/media_content_model.dart';

/// مشغل الملفات الصوتية المحلية
class AudioPlayerWidget extends StatefulWidget {
  final bool showVisualizer;
  final bool showPlaylist;
  final VoidCallback? onPlaylistToggle;

  const AudioPlayerWidget({
    Key? key,
    this.showVisualizer = true,
    this.showPlaylist = false,
    this.onPlaylistToggle,
  }) : super(key: key);

  @override
  State<AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends State<AudioPlayerWidget>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _waveController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    
    // تحكم في دوران القرص
    _rotationController = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(_rotationController);

    // تحكم في الموجات الصوتية
    _waveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _waveAnimation = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _waveController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaService>(
      builder: (context, mediaService, child) {
        final currentContent = mediaService.currentContent;
        final isPlaying = mediaService.isPlaying;

        // تحديث الرسوم المتحركة
        if (isPlaying && currentContent?.type == 'audio_file') {
          _rotationController.repeat();
          _waveController.repeat(reverse: true);
        } else {
          _rotationController.stop();
          _waveController.stop();
        }

        if (currentContent == null || currentContent.type != 'audio_file') {
          return _buildPlaceholder();
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Theme.of(context).primaryColor.withOpacity(0.1),
                Theme.of(context).primaryColor.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              // المشغل الرئيسي
              _buildMainPlayer(mediaService, currentContent),
              
              // المصور الصوتي
              if (widget.showVisualizer)
                _buildAudioVisualizer(isPlaying),
              
              // أدوات التحكم
              _buildPlayerControls(mediaService, currentContent),
              
              // قائمة التشغيل المصغرة
              if (widget.showPlaylist)
                _buildMiniPlaylist(mediaService),
            ],
          ),
        );
      },
    );
  }

  /// بناء العنصر النائب
  Widget _buildPlaceholder() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'لا يوجد ملف صوتي قيد التشغيل',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أضف ملف صوتي لبدء الاستماع',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء المشغل الرئيسي
  Widget _buildMainPlayer(MediaService mediaService, MediaContent content) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // غلاف الألبوم المتحرك
          _buildAlbumCover(content),
          
          const SizedBox(width: 20),
          
          // معلومات الأغنية
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  content.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  content.audioData?.fileName ?? 'ملف صوتي',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatFileSize(content.audioData?.fileSize ?? 0),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          
          // زر القائمة
          IconButton(
            onPressed: widget.onPlaylistToggle,
            icon: const Icon(Icons.queue_music),
          ),
        ],
      ),
    );
  }

  /// بناء غلاف الألبوم المتحرك
  Widget _buildAlbumCover(MediaContent content) {
    return AnimatedBuilder(
      animation: _rotationAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _rotationAnimation.value * 2 * 3.14159,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor,
                  Theme.of(context).primaryColor.withOpacity(0.7),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.music_note,
              color: Colors.white,
              size: 40,
            ),
          ),
        );
      },
    );
  }

  /// بناء المصور الصوتي
  Widget _buildAudioVisualizer(bool isPlaying) {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(20, (index) {
          return AnimatedBuilder(
            animation: _waveAnimation,
            builder: (context, child) {
              final height = isPlaying 
                  ? (20 + (40 * _waveAnimation.value * (0.5 + 0.5 * (index % 3))))
                  : 20.0;
              
              return Container(
                width: 3,
                height: height,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(
                    isPlaying ? 0.7 : 0.3,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            },
          );
        }),
      ),
    );
  }

  /// بناء أدوات التحكم
  Widget _buildPlayerControls(MediaService mediaService, MediaContent content) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // شريط التقدم
          _buildProgressBar(mediaService),
          
          const SizedBox(height: 20),
          
          // أزرار التحكم
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // زر الترجيع
              IconButton(
                onPressed: () {
                  final newPosition = (mediaService.currentPosition - 15)
                      .clamp(0.0, mediaService.duration);
                  mediaService.seekTo(newPosition);
                },
                icon: const Icon(Icons.replay_15),
                iconSize: 28,
              ),
              
              // زر التشغيل السابق
              IconButton(
                onPressed: () => _playPrevious(mediaService),
                icon: const Icon(Icons.skip_previous),
                iconSize: 32,
              ),
              
              // زر التشغيل/الإيقاف
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
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
                    size: 36,
                  ),
                ),
              ),
              
              // زر التشغيل التالي
              IconButton(
                onPressed: () => _playNext(mediaService),
                icon: const Icon(Icons.skip_next),
                iconSize: 32,
              ),
              
              // زر التقديم
              IconButton(
                onPressed: () {
                  final newPosition = (mediaService.currentPosition + 15)
                      .clamp(0.0, mediaService.duration);
                  mediaService.seekTo(newPosition);
                },
                icon: const Icon(Icons.forward_15),
                iconSize: 28,
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // أزرار إضافية
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // زر التكرار
              IconButton(
                onPressed: () {
                  // تبديل وضع التكرار
                },
                icon: const Icon(Icons.repeat),
                color: Colors.grey[600],
              ),
              
              // زر الخلط
              IconButton(
                onPressed: () {
                  // تبديل وضع الخلط
                },
                icon: const Icon(Icons.shuffle),
                color: Colors.grey[600],
              ),
              
              // زر مستوى الصوت
              IconButton(
                onPressed: () => _showVolumeDialog(mediaService),
                icon: Icon(
                  mediaService.volume > 0.5
                      ? Icons.volume_up
                      : mediaService.volume > 0
                          ? Icons.volume_down
                          : Icons.volume_off,
                ),
                color: Colors.grey[600],
              ),
              
              // زر المشاركة
              IconButton(
                onPressed: () => _shareAudio(content),
                icon: const Icon(Icons.share),
                color: Colors.grey[600],
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// بناء شريط التقدم
  Widget _buildProgressBar(MediaService mediaService) {
    return Column(
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Theme.of(context).primaryColor,
            inactiveTrackColor: Colors.grey[300],
            thumbColor: Theme.of(context).primaryColor,
            overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
          ),
          child: Slider(
            value: mediaService.currentPosition.clamp(0.0, mediaService.duration),
            max: mediaService.duration > 0 ? mediaService.duration : 1.0,
            onChanged: (value) {
              // تحديث محلي فوري للاستجابة السريعة
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
    );
  }

  /// بناء قائمة التشغيل المصغرة
  Widget _buildMiniPlaylist(MediaService mediaService) {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'قائمة التشغيل',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: mediaService.roomPlaylist.length,
              itemBuilder: (context, index) {
                final content = mediaService.roomPlaylist[index];
                final isActive = content.contentId == mediaService.currentContent?.contentId;
                
                return Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () {
                      if (!isActive) {
                        mediaService.startContent(content.contentId);
                      }
                    },
                    child: Column(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: isActive 
                                ? Theme.of(context).primaryColor
                                : Colors.grey[300],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.music_note,
                            color: isActive ? Colors.white : Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          content.title,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                            color: isActive 
                                ? Theme.of(context).primaryColor
                                : Colors.grey[700],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// تشغيل الأغنية السابقة
  void _playPrevious(MediaService mediaService) {
    final currentIndex = mediaService.roomPlaylist.indexWhere(
      (content) => content.contentId == mediaService.currentContent?.contentId,
    );
    
    if (currentIndex > 0) {
      final previousContent = mediaService.roomPlaylist[currentIndex - 1];
      mediaService.startContent(previousContent.contentId);
    }
  }

  /// تشغيل الأغنية التالية
  void _playNext(MediaService mediaService) {
    final currentIndex = mediaService.roomPlaylist.indexWhere(
      (content) => content.contentId == mediaService.currentContent?.contentId,
    );
    
    if (currentIndex < mediaService.roomPlaylist.length - 1) {
      final nextContent = mediaService.roomPlaylist[currentIndex + 1];
      mediaService.startContent(nextContent.contentId);
    }
  }

  /// عرض حوار مستوى الصوت
  void _showVolumeDialog(MediaService mediaService) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('مستوى الصوت'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  value: mediaService.volume,
                  onChanged: (value) {
                    setState(() {
                      mediaService.changeVolume(value * 100);
                    });
                  },
                ),
                Text('${(mediaService.volume * 100).round()}%'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  /// مشاركة الملف الصوتي
  void _shareAudio(MediaContent content) {
    // يمكن إضافة منطق المشاركة هنا
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('مشاركة: ${content.title}'),
      ),
    );
  }

  /// تنسيق حجم الملف
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// تنسيق المدة الزمنية
  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${twoDigits(minutes)}:${twoDigits(seconds)}';
    } else {
      return '${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
  }
}

