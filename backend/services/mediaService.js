const MediaContent = require('../models/MediaContent');
const { socketService } = require('./socketService');

/**
 * خدمة إدارة الوسائط والمزامنة
 * تدير تشغيل YouTube والموسيقى في الغرف الصوتية
 */
class MediaService {
  constructor() {
    this.activeRooms = new Map(); // roomId -> mediaState
    this.syncIntervals = new Map(); // roomId -> intervalId
  }

  /**
   * بدء تشغيل محتوى في الغرفة
   */
  async startContent(roomId, contentId, userId, startPosition = 0) {
    try {
      // البحث عن المحتوى
      const content = await MediaContent.findOne({ contentId, roomId });
      if (!content) {
        throw new Error('المحتوى غير موجود');
      }

      // التحقق من الصلاحيات
      if (!content.canUserControl(userId, 'play')) {
        throw new Error('غير مصرح لك بتشغيل هذا المحتوى');
      }

      // إيقاف أي محتوى نشط آخر
      await this.stopAllContent(roomId);

      // تحديث حالة المحتوى
      await content.updatePlaybackState({
        isPlaying: true,
        currentPosition: startPosition,
        lastUpdated: new Date()
      });

      content.status = 'active';
      await content.save();

      // تسجيل التشغيل
      await content.recordPlay();

      // بدء المزامنة
      this.startSyncForRoom(roomId, contentId);

      // إشعار جميع المستخدمين في الغرفة
      socketService.emitToRoom(roomId, 'media_started', {
        contentId,
        content: await this.getContentInfo(content),
        startedBy: userId,
        timestamp: new Date().toISOString()
      });

      return {
        success: true,
        message: 'تم بدء تشغيل المحتوى',
        content: await this.getContentInfo(content)
      };

    } catch (error) {
      console.error('خطأ في بدء تشغيل المحتوى:', error);
      throw error;
    }
  }

  /**
   * إيقاف تشغيل المحتوى
   */
  async pauseContent(roomId, contentId, userId) {
    try {
      const content = await MediaContent.findOne({ contentId, roomId });
      if (!content) {
        throw new Error('المحتوى غير موجود');
      }

      if (!content.canUserControl(userId, 'pause')) {
        throw new Error('غير مصرح لك بإيقاف هذا المحتوى');
      }

      await content.updatePlaybackState({
        isPlaying: false,
        lastUpdated: new Date()
      });

      content.status = 'paused';
      await content.save();

      // إيقاف المزامنة
      this.stopSyncForRoom(roomId);

      // إشعار المستخدمين
      socketService.emitToRoom(roomId, 'media_paused', {
        contentId,
        pausedBy: userId,
        currentPosition: content.playbackState.currentPosition,
        timestamp: new Date().toISOString()
      });

      return {
        success: true,
        message: 'تم إيقاف تشغيل المحتوى مؤقتاً'
      };

    } catch (error) {
      console.error('خطأ في إيقاف المحتوى:', error);
      throw error;
    }
  }

  /**
   * إيقاف جميع المحتوى في الغرفة
   */
  async stopAllContent(roomId) {
    try {
      await MediaContent.updateMany(
        { roomId, status: { $in: ['active', 'paused'] } },
        { 
          status: 'stopped',
          'playbackState.isPlaying': false,
          'playbackState.currentPosition': 0,
          'playbackState.lastUpdated': new Date()
        }
      );

      this.stopSyncForRoom(roomId);

      socketService.emitToRoom(roomId, 'media_stopped', {
        timestamp: new Date().toISOString()
      });

      return { success: true };

    } catch (error) {
      console.error('خطأ في إيقاف جميع المحتوى:', error);
      throw error;
    }
  }

  /**
   * تغيير موقع التشغيل
   */
  async seekContent(roomId, contentId, userId, position) {
    try {
      const content = await MediaContent.findOne({ contentId, roomId });
      if (!content) {
        throw new Error('المحتوى غير موجود');
      }

      if (!content.canUserControl(userId, 'seek')) {
        throw new Error('غير مصرح لك بتغيير موقع التشغيل');
      }

      await content.updatePlaybackState({
        currentPosition: position,
        lastUpdated: new Date()
      });

      // إشعار المستخدمين
      socketService.emitToRoom(roomId, 'media_seeked', {
        contentId,
        position,
        seekedBy: userId,
        timestamp: new Date().toISOString()
      });

      return {
        success: true,
        message: 'تم تغيير موقع التشغيل',
        position
      };

    } catch (error) {
      console.error('خطأ في تغيير موقع التشغيل:', error);
      throw error;
    }
  }

  /**
   * تغيير مستوى الصوت
   */
  async changeVolume(roomId, contentId, userId, volume) {
    try {
      const content = await MediaContent.findOne({ contentId, roomId });
      if (!content) {
        throw new Error('المحتوى غير موجود');
      }

      if (!content.canUserControl(userId, 'volume')) {
        throw new Error('غير مصرح لك بتغيير مستوى الصوت');
      }

      await content.updatePlaybackState({
        volume: Math.max(0, Math.min(100, volume)),
        lastUpdated: new Date()
      });

      // إشعار المستخدمين
      socketService.emitToRoom(roomId, 'media_volume_changed', {
        contentId,
        volume: content.playbackState.volume,
        changedBy: userId,
        timestamp: new Date().toISOString()
      });

      return {
        success: true,
        message: 'تم تغيير مستوى الصوت',
        volume: content.playbackState.volume
      };

    } catch (error) {
      console.error('خطأ في تغيير مستوى الصوت:', error);
      throw error;
    }
  }

  /**
   * إضافة محتوى YouTube
   */
  async addYouTubeContent(roomId, videoId, userId, videoInfo) {
    try {
      const content = await MediaContent.createYouTubeContent(
        roomId, 
        videoId, 
        userId, 
        videoInfo
      );

      // إشعار المستخدمين
      socketService.emitToRoom(roomId, 'media_added', {
        content: await this.getContentInfo(content),
        addedBy: userId,
        timestamp: new Date().toISOString()
      });

      return {
        success: true,
        message: 'تم إضافة فيديو YouTube',
        content: await this.getContentInfo(content)
      };

    } catch (error) {
      console.error('خطأ في إضافة محتوى YouTube:', error);
      throw error;
    }
  }

  /**
   * إضافة ملف صوتي
   */
  async addAudioFile(roomId, fileInfo, userId) {
    try {
      const content = await MediaContent.createAudioContent(
        roomId,
        fileInfo,
        userId
      );

      // إشعار المستخدمين
      socketService.emitToRoom(roomId, 'media_added', {
        content: await this.getContentInfo(content),
        addedBy: userId,
        timestamp: new Date().toISOString()
      });

      return {
        success: true,
        message: 'تم إضافة الملف الصوتي',
        content: await this.getContentInfo(content)
      };

    } catch (error) {
      console.error('خطأ في إضافة الملف الصوتي:', error);
      throw error;
    }
  }

  /**
   * بدء المزامنة للغرفة
   */
  startSyncForRoom(roomId, contentId) {
    // إيقاف المزامنة السابقة إن وجدت
    this.stopSyncForRoom(roomId);

    // بدء مزامنة جديدة كل ثانيتين
    const intervalId = setInterval(async () => {
      try {
        const content = await MediaContent.findOne({ contentId, roomId });
        if (!content || !content.playbackState.isPlaying) {
          this.stopSyncForRoom(roomId);
          return;
        }

        // حساب الموقع الحالي
        const now = new Date();
        const timeDiff = (now - content.playbackState.lastUpdated) / 1000;
        const currentPosition = content.playbackState.currentPosition + 
          (timeDiff * content.playbackState.playbackSpeed);

        // تحديث الموقع
        await content.updatePlaybackState({
          currentPosition,
          lastUpdated: now
        });

        // إرسال معلومات المزامنة
        socketService.emitToRoom(roomId, 'media_sync', {
          contentId,
          currentPosition,
          isPlaying: content.playbackState.isPlaying,
          volume: content.playbackState.volume,
          playbackSpeed: content.playbackState.playbackSpeed,
          timestamp: now.toISOString()
        });

      } catch (error) {
        console.error('خطأ في المزامنة:', error);
        this.stopSyncForRoom(roomId);
      }
    }, 2000); // كل ثانيتين

    this.syncIntervals.set(roomId, intervalId);
  }

  /**
   * إيقاف المزامنة للغرفة
   */
  stopSyncForRoom(roomId) {
    const intervalId = this.syncIntervals.get(roomId);
    if (intervalId) {
      clearInterval(intervalId);
      this.syncIntervals.delete(roomId);
    }
  }

  /**
   * الحصول على معلومات المحتوى
   */
  async getContentInfo(content) {
    const info = {
      contentId: content.contentId,
      type: content.type,
      title: content.title,
      description: content.description,
      status: content.status,
      playbackState: content.playbackState,
      stats: content.stats,
      metadata: content.metadata
    };

    if (content.type === 'youtube') {
      info.youtubeData = content.youtubeData;
    } else if (content.type === 'audio_file') {
      info.audioData = content.audioData;
    } else if (content.type === 'playlist') {
      info.playlistData = content.playlistData;
    }

    return info;
  }

  /**
   * الحصول على المحتوى النشط في الغرفة
   */
  async getActiveContent(roomId) {
    try {
      const content = await MediaContent.getActiveContent(roomId);
      if (!content) {
        return null;
      }

      return await this.getContentInfo(content);

    } catch (error) {
      console.error('خطأ في الحصول على المحتوى النشط:', error);
      return null;
    }
  }

  /**
   * الحصول على قائمة المحتوى في الغرفة
   */
  async getRoomContent(roomId, page = 1, limit = 20) {
    try {
      const contents = await MediaContent.getRoomContent(roomId, page, limit);
      
      return {
        contents: await Promise.all(
          contents.map(content => this.getContentInfo(content))
        ),
        pagination: {
          page,
          limit,
          total: await MediaContent.countDocuments({ roomId })
        }
      };

    } catch (error) {
      console.error('خطأ في الحصول على محتوى الغرفة:', error);
      throw error;
    }
  }

  /**
   * حذف محتوى
   */
  async deleteContent(roomId, contentId, userId) {
    try {
      const content = await MediaContent.findOne({ contentId, roomId });
      if (!content) {
        throw new Error('المحتوى غير موجود');
      }

      // التحقق من الصلاحيات (المالك أو من أضاف المحتوى)
      if (content.metadata.addedBy.toString() !== userId.toString() &&
          !content.canUserControl(userId, 'delete')) {
        throw new Error('غير مصرح لك بحذف هذا المحتوى');
      }

      // إيقاف المحتوى إذا كان نشطاً
      if (content.status === 'active') {
        await this.stopAllContent(roomId);
      }

      // حذف المحتوى
      await MediaContent.deleteOne({ contentId, roomId });

      // إشعار المستخدمين
      socketService.emitToRoom(roomId, 'media_deleted', {
        contentId,
        deletedBy: userId,
        timestamp: new Date().toISOString()
      });

      return {
        success: true,
        message: 'تم حذف المحتوى'
      };

    } catch (error) {
      console.error('خطأ في حذف المحتوى:', error);
      throw error;
    }
  }

  /**
   * تنظيف الموارد عند إغلاق الخدمة
   */
  cleanup() {
    // إيقاف جميع المزامنات
    for (const [roomId, intervalId] of this.syncIntervals) {
      clearInterval(intervalId);
    }
    this.syncIntervals.clear();
    this.activeRooms.clear();
  }
}

// إنشاء instance واحد من الخدمة
const mediaService = new MediaService();

// تنظيف الموارد عند إغلاق التطبيق
process.on('SIGINT', () => {
  mediaService.cleanup();
  process.exit(0);
});

process.on('SIGTERM', () => {
  mediaService.cleanup();
  process.exit(0);
});

module.exports = { mediaService };

