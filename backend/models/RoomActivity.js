const mongoose = require('mongoose');

// نموذج أنشطة الغرفة (للشريط الشفاف)
const roomActivitySchema = new mongoose.Schema({
  // معرف النشاط
  activityId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  
  // الغرفة التي حدث فيها النشاط
  roomId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Room',
    required: true,
    index: true
  },
  
  // نوع النشاط
  activityType: {
    type: String,
    enum: [
      'user_joined',        // انضمام مستخدم للغرفة
      'user_left',          // مغادرة مستخدم للغرفة
      'user_moved_to_mic',  // انتقال مستخدم للمايك
      'user_left_mic',      // مغادرة مستخدم للمايك
      'user_muted',         // كتم مستخدم
      'user_unmuted',       // إلغاء كتم مستخدم
      'user_kicked',        // طرد مستخدم
      'user_banned',        // حظر مستخدم
      'admin_assigned',     // تعيين مدير
      'admin_removed',      // إزالة مدير
      'mic_count_changed',  // تغيير عدد المايكات
      'room_settings_changed', // تغيير إعدادات الغرفة
      'youtube_started',    // بدء فيديو يوتيوب
      'youtube_stopped',    // إيقاف فيديو يوتيوب
      'music_started',      // بدء تشغيل موسيقى
      'music_stopped',      // إيقاف موسيقى
      'chat_disabled',      // تعطيل الدردشة
      'chat_enabled',       // تفعيل الدردشة
      'room_created',       // إنشاء الغرفة
      'room_ended'          // انتهاء الغرفة
    ],
    required: true
  },
  
  // المستخدم الذي قام بالنشاط
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  
  // المستخدم المستهدف (في حالة الطرد، الكتم، إلخ)
  targetUserId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  
  // تفاصيل النشاط
  details: {
    // للانتقال بين المقاعد
    seatInfo: {
      fromSeat: Number,
      toSeat: Number,
      seatType: {
        type: String,
        enum: ['vip', 'guest', 'waiting_queue']
      }
    },
    
    // لتغيير عدد المايكات
    micChange: {
      fromCount: Number,
      toCount: Number,
      affectedUsers: [{
        userId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: 'User'
        },
        action: {
          type: String,
          enum: ['moved_to_queue', 'moved_to_seat', 'removed']
        }
      }]
    },
    
    // لتغيير الإعدادات
    settingsChange: {
      setting: String,
      oldValue: mongoose.Schema.Types.Mixed,
      newValue: mongoose.Schema.Types.Mixed
    },
    
    // للوسائط (يوتيوب، موسيقى)
    mediaInfo: {
      title: String,
      url: String,
      duration: Number,
      thumbnail: String
    },
    
    // للحظر والطرد
    moderationInfo: {
      reason: String,
      duration: Number, // بالدقائق، null للحظر الدائم
      evidence: String
    },
    
    // معلومات إضافية
    metadata: {
      type: Map,
      of: mongoose.Schema.Types.Mixed
    }
  },
  
  // النص المعروض في الشريط
  displayText: {
    ar: String, // النص بالعربية
    en: String  // النص بالإنجليزية
  },
  
  // أولوية العرض
  priority: {
    type: String,
    enum: ['low', 'normal', 'high', 'urgent'],
    default: 'normal'
  },
  
  // حالة النشاط
  status: {
    type: String,
    enum: ['active', 'archived', 'hidden'],
    default: 'active'
  },
  
  // مدة العرض (بالثواني)
  displayDuration: {
    type: Number,
    default: 5 // 5 ثواني افتراضياً
  },
  
  // هل يجب عرضه في الشريط؟
  showInBar: {
    type: Boolean,
    default: true
  },
  
  // معلومات الجهاز
  deviceInfo: {
    platform: String,
    userAgent: String,
    ipAddress: String
  },
  
  // تواريخ مهمة
  createdAt: {
    type: Date,
    default: Date.now,
    index: true
  },
  expiresAt: {
    type: Date,
    default: function() {
      // انتهاء صلاحية النشاط بعد 24 ساعة
      return new Date(Date.now() + 24 * 60 * 60 * 1000);
    },
    index: true
  }
}, {
  timestamps: true
});

// فهارس للأداء
roomActivitySchema.index({ roomId: 1, createdAt: -1 });
roomActivitySchema.index({ activityType: 1, status: 1 });
roomActivitySchema.index({ userId: 1, createdAt: -1 });
roomActivitySchema.index({ priority: 1, showInBar: 1 });
roomActivitySchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

// Methods للنشاط
roomActivitySchema.methods = {
  // توليد النص المعروض
  generateDisplayText() {
    const activityTexts = {
      'user_joined': {
        ar: `انضم مستخدم جديد`,
        en: `New user joined`
      },
      'user_left': {
        ar: `غادر مستخدم`,
        en: `User left`
      },
      'user_moved_to_mic': {
        ar: `انتقل إلى المايك ${this.details.seatInfo?.toSeat}`,
        en: `Moved to mic ${this.details.seatInfo?.toSeat}`
      },
      'user_left_mic': {
        ar: `غادر المايك ${this.details.seatInfo?.fromSeat}`,
        en: `Left mic ${this.details.seatInfo?.fromSeat}`
      },
      'user_muted': {
        ar: `تم كتم مستخدم`,
        en: `User was muted`
      },
      'user_unmuted': {
        ar: `تم إلغاء كتم مستخدم`,
        en: `User was unmuted`
      },
      'user_kicked': {
        ar: `تم طرد مستخدم`,
        en: `User was kicked`
      },
      'admin_assigned': {
        ar: `تم تعيين مدير جديد`,
        en: `New admin assigned`
      },
      'mic_count_changed': {
        ar: `تم تغيير عدد المايكات إلى ${this.details.micChange?.toCount}`,
        en: `Mic count changed to ${this.details.micChange?.toCount}`
      },
      'youtube_started': {
        ar: `🎥 بدأ تشغيل فيديو`,
        en: `🎥 Video started`
      },
      'youtube_stopped': {
        ar: `⏹️ توقف الفيديو`,
        en: `⏹️ Video stopped`
      },
      'music_started': {
        ar: `🎵 بدأ تشغيل الموسيقى`,
        en: `🎵 Music started`
      },
      'music_stopped': {
        ar: `⏸️ توقفت الموسيقى`,
        en: `⏸️ Music stopped`
      },
      'chat_disabled': {
        ar: `🚫 تم تعطيل الدردشة`,
        en: `🚫 Chat disabled`
      },
      'chat_enabled': {
        ar: `💬 تم تفعيل الدردشة`,
        en: `💬 Chat enabled`
      },
      'room_created': {
        ar: `🎉 تم إنشاء الغرفة`,
        en: `🎉 Room created`
      },
      'room_ended': {
        ar: `👋 انتهت الجلسة`,
        en: `👋 Session ended`
      }
    };
    
    const texts = activityTexts[this.activityType];
    if (texts) {
      this.displayText = texts;
    }
    
    return this.displayText;
  },
  
  // تحديد أولوية العرض
  setPriority() {
    const highPriorityActivities = [
      'user_kicked', 'user_banned', 'admin_assigned', 
      'mic_count_changed', 'room_ended'
    ];
    
    const urgentActivities = [
      'room_created', 'youtube_started', 'music_started'
    ];
    
    if (urgentActivities.includes(this.activityType)) {
      this.priority = 'urgent';
      this.displayDuration = 8;
    } else if (highPriorityActivities.includes(this.activityType)) {
      this.priority = 'high';
      this.displayDuration = 6;
    } else {
      this.priority = 'normal';
      this.displayDuration = 4;
    }
  },
  
  // تحديد ما إذا كان يجب عرضه في الشريط
  shouldShowInBar() {
    const hiddenActivities = [
      'room_settings_changed' // إعدادات داخلية لا تحتاج عرض
    ];
    
    this.showInBar = !hiddenActivities.includes(this.activityType);
    return this.showInBar;
  }
};

// Static methods
roomActivitySchema.statics = {
  // إنشاء نشاط جديد
  createActivity(roomId, activityType, userId, details = {}, targetUserId = null) {
    const activityId = `${roomId}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    const activity = new this({
      activityId,
      roomId,
      activityType,
      userId,
      targetUserId,
      details
    });
    
    // توليد النص والأولوية
    activity.generateDisplayText();
    activity.setPriority();
    activity.shouldShowInBar();
    
    return activity.save();
  },
  
  // الحصول على أنشطة الغرفة للشريط
  getBarActivities(roomId, limit = 20) {
    return this.find({
      roomId,
      status: 'active',
      showInBar: true,
      expiresAt: { $gt: new Date() }
    })
    .populate('userId', 'displayName profilePicture')
    .populate('targetUserId', 'displayName profilePicture')
    .sort({ priority: -1, createdAt: -1 })
    .limit(limit);
  },
  
  // الحصول على المستخدمين المتصلين حالياً
  getCurrentUsers(roomId) {
    return this.aggregate([
      {
        $match: {
          roomId: mongoose.Types.ObjectId(roomId),
          activityType: { $in: ['user_joined', 'user_left'] },
          createdAt: { $gte: new Date(Date.now() - 24 * 60 * 60 * 1000) }
        }
      },
      {
        $sort: { userId: 1, createdAt: -1 }
      },
      {
        $group: {
          _id: '$userId',
          lastActivity: { $first: '$activityType' },
          lastSeen: { $first: '$createdAt' }
        }
      },
      {
        $match: {
          lastActivity: 'user_joined'
        }
      },
      {
        $lookup: {
          from: 'users',
          localField: '_id',
          foreignField: '_id',
          as: 'userInfo'
        }
      },
      {
        $unwind: '$userInfo'
      },
      {
        $project: {
          userId: '$_id',
          displayName: '$userInfo.displayName',
          profilePicture: '$userInfo.profilePicture',
          lastSeen: 1,
          isOnline: {
            $gt: ['$lastSeen', new Date(Date.now() - 5 * 60 * 1000)] // آخر 5 دقائق
          }
        }
      },
      {
        $sort: { lastSeen: -1 }
      }
    ]);
  },
  
  // تنظيف الأنشطة القديمة
  cleanupOldActivities(hoursOld = 24) {
    const cutoffDate = new Date(Date.now() - hoursOld * 60 * 60 * 1000);
    return this.deleteMany({
      createdAt: { $lt: cutoffDate },
      priority: { $in: ['low', 'normal'] }
    });
  },
  
  // إحصائيات النشاط
  getActivityStats(roomId, timeframe = '1h') {
    const timeframes = {
      '1h': 1 * 60 * 60 * 1000,
      '24h': 24 * 60 * 60 * 1000,
      '7d': 7 * 24 * 60 * 60 * 1000
    };
    
    const since = new Date(Date.now() - timeframes[timeframe]);
    
    return this.aggregate([
      {
        $match: {
          roomId: mongoose.Types.ObjectId(roomId),
          createdAt: { $gte: since }
        }
      },
      {
        $group: {
          _id: '$activityType',
          count: { $sum: 1 },
          lastOccurrence: { $max: '$createdAt' }
        }
      },
      {
        $sort: { count: -1 }
      }
    ]);
  }
};

// نموذج حالة المستخدمين في الغرفة (للشريط الشفاف)
const roomUserStatusSchema = new mongoose.Schema({
  roomId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Room',
    required: true,
    index: true
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  
  // حالة المستخدم في الغرفة
  status: {
    type: String,
    enum: ['online', 'away', 'offline'],
    default: 'online'
  },
  
  // دور المستخدم
  role: {
    type: String,
    enum: ['owner', 'admin', 'speaker', 'listener', 'guest'],
    default: 'listener'
  },
  
  // معلومات المقعد
  seatInfo: {
    seatNumber: Number,
    isVIP: Boolean,
    isMuted: Boolean,
    joinedSeatAt: Date
  },
  
  // معلومات الاتصال
  connectionInfo: {
    joinedAt: Date,
    lastSeen: Date,
    deviceType: String,
    platform: String,
    connectionQuality: {
      type: String,
      enum: ['excellent', 'good', 'fair', 'poor'],
      default: 'good'
    }
  },
  
  // إعدادات العرض في الشريط
  displaySettings: {
    showInBar: { type: Boolean, default: true },
    customColor: String,
    customBadge: String,
    priority: { type: Number, default: 0 }
  },
  
  // آخر نشاط
  lastActivity: {
    type: Date,
    default: Date.now,
    index: true
  }
}, {
  timestamps: true
});

// فهارس مركبة
roomUserStatusSchema.index({ roomId: 1, status: 1, lastActivity: -1 });
roomUserStatusSchema.index({ userId: 1, roomId: 1 }, { unique: true });

module.exports = {
  RoomActivity: mongoose.model('RoomActivity', roomActivitySchema),
  RoomUserStatus: mongoose.model('RoomUserStatus', roomUserStatusSchema)
};

