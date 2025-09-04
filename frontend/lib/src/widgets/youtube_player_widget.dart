import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../services/media_service.dart';
import '../models/media_content_model.dart';

/// مشغل YouTube مع المزامنة
class YouTubePlayerWidget extends StatefulWidget {
  final bool showControls;
  final bool allowFullScreen;
  final VoidCallback? onFullScreenToggle;

  const YouTubePlayerWidget({
    Key? key,
    this.showControls = true,
    this.allowFullScreen = true,
    this.onFullScreenToggle,
  }) : super(key: key);

  @override
  State<YouTubePlayerWidget> createState() => _YouTubePlayerWidgetState();
}

class _YouTubePlayerWidgetState extends State<YouTubePlayerWidget>
    with WidgetsBindingObserver {
  bool _isFullScreen = false;
  bool _isControlsVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final mediaService = Provider.of<MediaService>(context, listen: false);
    
    // إيقاف مؤقت عند الخروج من التطبيق
    if (state == AppLifecycleState.paused) {
      mediaService.youtubeController?.pause();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaService>(
      builder: (context, mediaService, child) {
        final controller = mediaService.youtubeController;
        final currentContent = mediaService.currentContent;

        if (controller == null || 
            currentContent == null || 
            currentContent.type != 'youtube') {
          return _buildPlaceholder();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // مشغل YouTube
                YoutubePlayer(
                  controller: controller,
                  showVideoProgressIndicator: true,
                  progressIndicatorColor: Theme.of(context).primaryColor,
                  progressColors: ProgressBarColors(
                    playedColor: Theme.of(context).primaryColor,
                    handleColor: Theme.of(context).primaryColor,
                  ),
                  onReady: () {
                    debugPrint('YouTube Player جاهز');
                  },
                  onEnded: (metaData) {
                    _handleVideoEnded();
                  },
                ),

                // طبقة التحكم المخصصة
                if (widget.showControls)
                  Positioned.fill(
                    child: _buildCustomControls(mediaService, controller),
                  ),

                // معلومات الفيديو
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: _buildVideoInfo(currentContent),
                ),

                // أزرار الإجراءات
                if (widget.allowFullScreen)
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _buildActionButtons(controller),
                  ),
              ],
            ),
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
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.video_library_outlined,
              size: 48,
              color: Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              'لا يوجد فيديو قيد التشغيل',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'أضف رابط YouTube لبدء المشاهدة',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// بناء أدوات التحكم المخصصة
  Widget _buildCustomControls(
    MediaService mediaService,
    YoutubePlayerController controller,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _isControlsVisible = !_isControlsVisible;
        });
      },
      child: AnimatedOpacity(
        opacity: _isControlsVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.7),
                Colors.transparent,
                Colors.black.withOpacity(0.7),
              ],
            ),
          ),
          child: Column(
            children: [
              const Spacer(),
              
              // أدوات التحكم السفلية
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // شريط التقدم
                    _buildProgressBar(mediaService, controller),
                    
                    const SizedBox(height: 16),
                    
                    // أزرار التحكم
                    _buildControlButtons(mediaService, controller),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// بناء شريط التقدم
  Widget _buildProgressBar(
    MediaService mediaService,
    YoutubePlayerController controller,
  ) {
    return Row(
      children: [
        // الوقت الحالي
        Text(
          _formatDuration(Duration(seconds: mediaService.currentPosition.toInt())),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
        
        const SizedBox(width: 8),
        
        // شريط التقدم
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Theme.of(context).primaryColor,
              inactiveTrackColor: Colors.white.withOpacity(0.3),
              thumbColor: Theme.of(context).primaryColor,
              overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            ),
            child: Slider(
              value: mediaService.currentPosition.clamp(0.0, mediaService.duration),
              max: mediaService.duration > 0 ? mediaService.duration : 1.0,
              onChanged: (value) {
                // تحديث محلي فوري
                controller.seekTo(Duration(seconds: value.toInt()));
              },
              onChangeEnd: (value) {
                // إرسال للخادم للمزامنة
                mediaService.seekTo(value);
              },
            ),
          ),
        ),
        
        const SizedBox(width: 8),
        
        // المدة الإجمالية
        Text(
          _formatDuration(Duration(seconds: mediaService.duration.toInt())),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  /// بناء أزرار التحكم
  Widget _buildControlButtons(
    MediaService mediaService,
    YoutubePlayerController controller,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // زر الترجيع
        IconButton(
          onPressed: () {
            final newPosition = (mediaService.currentPosition - 10).clamp(0.0, mediaService.duration);
            mediaService.seekTo(newPosition);
          },
          icon: const Icon(Icons.replay_10, color: Colors.white, size: 28),
        ),
        
        const SizedBox(width: 20),
        
        // زر التشغيل/الإيقاف
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
                  mediaService.currentContent!.contentId,
                  startPosition: mediaService.currentPosition,
                );
              }
            },
            icon: Icon(
              mediaService.isPlaying ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        
        const SizedBox(width: 20),
        
        // زر التقديم
        IconButton(
          onPressed: () {
            final newPosition = (mediaService.currentPosition + 10).clamp(0.0, mediaService.duration);
            mediaService.seekTo(newPosition);
          },
          icon: const Icon(Icons.forward_10, color: Colors.white, size: 28),
        ),
      ],
    );
  }

  /// بناء معلومات الفيديو
  Widget _buildVideoInfo(MediaContent content) {
    if (!_isControlsVisible) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            content.title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (content.youtubeData?.channelName != null) ...[
            const SizedBox(height: 4),
            Text(
              content.youtubeData!.channelName,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// بناء أزرار الإجراءات
  Widget _buildActionButtons(YoutubePlayerController controller) {
    return Column(
      children: [
        // زر ملء الشاشة
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: _toggleFullScreen,
            icon: Icon(
              _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
              color: Colors.white,
            ),
          ),
        ),
        
        const SizedBox(height: 8),
        
        // زر الإعدادات
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            onPressed: () => _showSettingsDialog(context),
            icon: const Icon(
              Icons.settings,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  /// تبديل ملء الشاشة
  void _toggleFullScreen() {
    setState(() {
      _isFullScreen = !_isFullScreen;
    });

    if (_isFullScreen) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
    }

    widget.onFullScreenToggle?.call();
  }

  /// معالجة انتهاء الفيديو
  void _handleVideoEnded() {
    final mediaService = Provider.of<MediaService>(context, listen: false);
    
    // يمكن إضافة منطق تشغيل الفيديو التالي هنا
    debugPrint('انتهى تشغيل الفيديو');
    
    // إيقاف التشغيل
    mediaService.stopContent();
  }

  /// عرض حوار الإعدادات
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إعدادات المشغل'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Consumer<MediaService>(
              builder: (context, mediaService, child) {
                return Column(
                  children: [
                    // مستوى الصوت
                    ListTile(
                      leading: const Icon(Icons.volume_up),
                      title: const Text('مستوى الصوت'),
                      subtitle: Slider(
                        value: mediaService.volume,
                        onChanged: (value) {
                          mediaService.changeVolume(value * 100);
                        },
                      ),
                    ),
                    
                    // سرعة التشغيل
                    ListTile(
                      leading: const Icon(Icons.speed),
                      title: const Text('سرعة التشغيل'),
                      subtitle: DropdownButton<double>(
                        value: mediaService.playbackSpeed,
                        items: const [
                          DropdownMenuItem(value: 0.5, child: Text('0.5x')),
                          DropdownMenuItem(value: 0.75, child: Text('0.75x')),
                          DropdownMenuItem(value: 1.0, child: Text('1.0x')),
                          DropdownMenuItem(value: 1.25, child: Text('1.25x')),
                          DropdownMenuItem(value: 1.5, child: Text('1.5x')),
                          DropdownMenuItem(value: 2.0, child: Text('2.0x')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            mediaService.youtubeController?.setPlaybackRate(value);
                          }
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
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

/// مشغل YouTube في وضع ملء الشاشة
class FullScreenYouTubePlayer extends StatefulWidget {
  final YoutubePlayerController controller;

  const FullScreenYouTubePlayer({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  State<FullScreenYouTubePlayer> createState() => _FullScreenYouTubePlayerState();
}

class _FullScreenYouTubePlayerState extends State<FullScreenYouTubePlayer> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: YoutubePlayer(
          controller: widget.controller,
          showVideoProgressIndicator: true,
          progressIndicatorColor: Theme.of(context).primaryColor,
        ),
      ),
    );
  }
}

