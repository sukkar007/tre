const mongoose = require('mongoose');

/**
 * نموذج المحتوى الوسائطي للغرف الصوتية
 * يدعم YouTube والموسيقى المحلية
 */
const mediaContentSchema = new mongoose.Schema({
  // معلومات أساسية
  contentId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  
  roomId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Room',
    required: true,
    index: true
  },
  
  // نوع المحتوى
  type: {
    type: String,
    enum: ['youtube', 'audio_file', 'playlist'],
    required: true
  },
  
  // معلومات المحتوى
  title: {
    type: String,
    required: true,
    maxlength: 200
  },
  
  description: {
    type: String,
    maxlength: 1000
  },
  
  // معلومات YouTube
  youtubeData: {
    videoId: String,
    channelName: String,
    duration: Number, // بالثواني
    thumbnailUrl: String,
    viewCount: Number,
    publishedAt: Date
  },
  
  // معلومات الملف الصوتي
  audioData: {
    fileName: String,
    fileSize: Number, // بالبايت
    duration: Number, // بالثواني
    format: String, // mp3, wav, etc.
    bitrate: Number,
    uploadedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    }
  },
  
  // معلومات قائمة التشغيل
  playlistData: {
    items: [{
      contentId: String,
      order: Number,
      addedBy: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      },
      addedAt: {
        type: Date,
        default: Date.now
      }
    }],
    totalDuration: Number,
    isShuffled: {
      type: Boolean,
      default: false
    },
    repeatMode: {
      type: String,
      enum: ['none', 'one', 'all'],
      default: 'none'
    }
  },
  
  // حالة التشغيل
  playbackState: {
    isPlaying: {
      type: Boolean,
      default: false
    },
    currentPosition: {
      type: Number,
      default: 0 // بالثواني
    },
    volume: {
      type: Number,
      min: 0,
      max: 100,
      default: 50
    },
    playbackSpeed: {
      type: Number,
      min: 0.25,
      max: 2.0,
      default: 1.0
    },
    lastUpdated: {
      type: Date,
      default: Date.now
    }
  },
  
  // التحكم والصلاحيات
  controls: {
    controlledBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    allowedControllers: [{
      userId: {
        type: mongoose.Schema.Types.ObjectId,
        ref: 'User'
      },
      permissions: [{
        type: String,
        enum: ['play', 'pause', 'seek', 'volume', 'skip', 'add_to_queue']
      }]
    }],
    isLocked: {
      type: Boolean,
      default: false
    }
  },
  
  // إعدادات المزامنة
  syncSettings: {
    isSynced: {
      type: Boolean,
      default: true
    },
    syncTolerance: {
      type: Number,
      default: 2 // ثواني
    },
    autoSync: {
      type: Boolean,
      default: true
    }
  },
  
  // إحصائيات
  stats: {
    totalPlays: {
      type: Number,
      default: 0
    },
    totalListeners: {
      type: Number,
      default: 0
    },
    averageRating: {
      type: Number,
      min: 0,
      max: 5,
      default: 0
    },
    ratingCount: {
      type: Number,
      default: 0
    },
    lastPlayed: Date
  },
  
  // معلومات إضافية
  metadata: {
    addedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    addedAt: {
      type: Date,
      default: Date.now
    },
    tags: [String],
    category: {
      type: String,
      enum: ['music', 'podcast', 'entertainment', 'education', 'other'],
      default: 'music'
    },
    language: String,
    isExplicit: {
      type: Boolean,
      default: false
    }
  },
  
  // حالة المحتوى
  status: {
    type: String,
    enum: ['active', 'paused', 'stopped', 'error', 'loading'],
    default: 'stopped'
  },
  
  // معلومات الخطأ
  errorInfo: {
    code: String,
    message: String,
    timestamp: Date
  }
}, {
  timestamps: true,
  collection: 'media_contents'
});

// فهارس للأداء
mediaContentSchema.index({ roomId: 1, status: 1 });
mediaContentSchema.index({ type: 1, 'metadata.addedAt': -1 });
mediaContentSchema.index({ 'youtubeData.videoId': 1 });
mediaContentSchema.index({ 'metadata.addedBy': 1 });

// Methods للنموذج
mediaContentSchema.methods = {
  
  /**
   * تحديث حالة التشغيل
   */
  updatePlaybackState(newState) {
    this.playbackState = {
      ...this.playbackState,
      ...newState,
      lastUpdated: new Date()
    };
    return this.save();
  },
  
  /**
   * إضافة مستمع جديد
   */
  addListener() {
    this.stats.totalListeners += 1;
    return this.save();
  },
  
  /**
   * تسجيل تشغيل جديد
   */
  recordPlay() {
    this.stats.totalPlays += 1;
    this.stats.lastPlayed = new Date();
    return this.save();
  },
  
  /**
   * إضافة تقييم
   */
  addRating(rating) {
    const currentTotal = this.stats.averageRating * this.stats.ratingCount;
    this.stats.ratingCount += 1;
    this.stats.averageRating = (currentTotal + rating) / this.stats.ratingCount;
    return this.save();
  },
  
  /**
   * التحقق من صلاحية التحكم
   */
  canUserControl(userId, action) {
    // المالك يمكنه التحكم في كل شيء
    if (this.controls.controlledBy.toString() === userId.toString()) {
      return true;
    }
    
    // التحقق من الصلاحيات المحددة
    const userPermissions = this.controls.allowedControllers.find(
      controller => controller.userId.toString() === userId.toString()
    );
    
    return userPermissions && userPermissions.permissions.includes(action);
  },
  
  /**
   * الحصول على معلومات المزامنة
   */
  getSyncInfo() {
    return {
      contentId: this.contentId,
      isPlaying: this.playbackState.isPlaying,
      currentPosition: this.playbackState.currentPosition,
      volume: this.playbackState.volume,
      playbackSpeed: this.playbackState.playbackSpeed,
      lastUpdated: this.playbackState.lastUpdated,
      isSynced: this.syncSettings.isSynced
    };
  },
  
  /**
   * تحديث موقع التشغيل مع المزامنة
   */
  syncPosition(position, timestamp) {
    const now = new Date();
    const timeDiff = (now - new Date(timestamp)) / 1000; // بالثواني
    
    if (this.playbackState.isPlaying) {
      // حساب الموقع المتوقع مع الأخذ في الاعتبار زمن التأخير
      const expectedPosition = position + (timeDiff * this.playbackState.playbackSpeed);
      this.playbackState.currentPosition = expectedPosition;
    } else {
      this.playbackState.currentPosition = position;
    }
    
    this.playbackState.lastUpdated = now;
    return this.save();
  }
};

// Static methods
mediaContentSchema.statics = {
  
  /**
   * إنشاء محتوى YouTube جديد
   */
  async createYouTubeContent(roomId, videoId, addedBy, videoInfo) {
    const contentId = `youtube_${videoId}_${Date.now()}`;
    
    return this.create({
      contentId,
      roomId,
      type: 'youtube',
      title: videoInfo.title,
      description: videoInfo.description,
      youtubeData: {
        videoId,
        channelName: videoInfo.channelName,
        duration: videoInfo.duration,
        thumbnailUrl: videoInfo.thumbnailUrl,
        viewCount: videoInfo.viewCount,
        publishedAt: videoInfo.publishedAt
      },
      metadata: {
        addedBy,
        category: 'entertainment'
      }
    });
  },
  
  /**
   * إنشاء محتوى صوتي جديد
   */
  async createAudioContent(roomId, fileInfo, addedBy) {
    const contentId = `audio_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    return this.create({
      contentId,
      roomId,
      type: 'audio_file',
      title: fileInfo.fileName,
      audioData: {
        fileName: fileInfo.fileName,
        fileSize: fileInfo.fileSize,
        duration: fileInfo.duration,
        format: fileInfo.format,
        bitrate: fileInfo.bitrate,
        uploadedBy: addedBy
      },
      metadata: {
        addedBy,
        category: 'music'
      }
    });
  },
  
  /**
   * إنشاء قائمة تشغيل جديدة
   */
  async createPlaylist(roomId, title, addedBy, items = []) {
    const contentId = `playlist_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    return this.create({
      contentId,
      roomId,
      type: 'playlist',
      title,
      playlistData: {
        items: items.map((item, index) => ({
          contentId: item.contentId,
          order: index,
          addedBy: item.addedBy || addedBy,
          addedAt: new Date()
        })),
        totalDuration: items.reduce((sum, item) => sum + (item.duration || 0), 0)
      },
      metadata: {
        addedBy,
        category: 'music'
      }
    });
  },
  
  /**
   * الحصول على المحتوى النشط في الغرفة
   */
  async getActiveContent(roomId) {
    return this.findOne({
      roomId,
      status: { $in: ['active', 'paused', 'loading'] }
    }).populate('metadata.addedBy', 'username avatar');
  },
  
  /**
   * الحصول على قائمة المحتوى في الغرفة
   */
  async getRoomContent(roomId, page = 1, limit = 20) {
    const skip = (page - 1) * limit;
    
    return this.find({ roomId })
      .populate('metadata.addedBy', 'username avatar')
      .sort({ 'metadata.addedAt': -1 })
      .skip(skip)
      .limit(limit);
  }
};

module.exports = mongoose.model('MediaContent', mediaContentSchema);

