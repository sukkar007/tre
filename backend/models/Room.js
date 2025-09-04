const mongoose = require('mongoose');

// نموذج المقعد في الغرفة
const seatSchema = new mongoose.Schema({
  seatNumber: {
    type: Number,
    required: true,
    min: 1,
    max: 20
  },
  userId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  isVIP: {
    type: Boolean,
    default: false
  },
  isMuted: {
    type: Boolean,
    default: false
  },
  isLocked: {
    type: Boolean,
    default: false
  },
  joinedAt: {
    type: Date,
    default: null
  }
});

// نموذج إعدادات الغرفة
const roomSettingsSchema = new mongoose.Schema({
  // إعدادات الدردشة
  chatSettings: {
    isEnabled: { type: Boolean, default: true },
    allowEmojis: { type: Boolean, default: true },
    allowImages: { type: Boolean, default: false },
    messageLimit: { type: Number, default: 100 }, // عدد الرسائل المحفوظة
    slowMode: { type: Number, default: 0 }, // ثواني بين الرسائل
    badWordsFilter: { type: Boolean, default: true }
  },
  
  // إعدادات اليوتيوب
  youtubeSettings: {
    isEnabled: { type: Boolean, default: false },
    currentVideoId: { type: String, default: null },
    currentVideoTitle: { type: String, default: null },
    isPlaying: { type: Boolean, default: false },
    currentTime: { type: Number, default: 0 },
    lastUpdated: { type: Date, default: Date.now },
    onlyAdminsCanControl: { type: Boolean, default: true }
  },
  
  // إعدادات الموسيقى
  musicSettings: {
    isEnabled: { type: Boolean, default: false },
    currentTrack: {
      name: { type: String, default: null },
      artist: { type: String, default: null },
      duration: { type: Number, default: 0 },
      currentTime: { type: Number, default: 0 }
    },
    volume: { type: Number, default: 50, min: 0, max: 100 },
    isPlaying: { type: Boolean, default: false },
    onlyAdminsCanControl: { type: Boolean, default: true }
  },
  
  // إعدادات الصوت
  audioSettings: {
    globalVolume: { type: Number, default: 100, min: 0, max: 100 },
    micAutoMute: { type: Boolean, default: false },
    micAutoMuteTime: { type: Number, default: 10 }, // ثواني
    echoReduction: { type: Boolean, default: true },
    noiseReduction: { type: Boolean, default: true }
  },
  
  // إعدادات الوصول
  accessSettings: {
    isPrivate: { type: Boolean, default: false },
    requireApproval: { type: Boolean, default: false },
    maxParticipants: { type: Number, default: 20, min: 2, max: 50 },
    allowGuests: { type: Boolean, default: true },
    minimumAge: { type: Number, default: 13, min: 13, max: 99 }
  },
  
  // إعدادات المايكات
  micSettings: {
    totalMics: { 
      type: Number, 
      default: 6, 
      enum: [2, 6, 12, 16, 20],
      validate: {
        validator: function(v) {
          return [2, 6, 12, 16, 20].includes(v);
        },
        message: 'عدد المايكات يجب أن يكون 2، 6، 12، 16، أو 20'
      }
    },
    vipMics: { 
      type: Number, 
      default: function() {
        // حساب عدد مايكات VIP بناءً على العدد الكلي
        const total = this.totalMics || 6;
        if (total === 2) return 0;
        if (total === 6) return 1;
        if (total === 12) return 2;
        if (total === 16) return 3;
        if (total === 20) return 4;
        return 1;
      }
    },
    guestMics: { 
      type: Number, 
      default: function() {
        const total = this.totalMics || 6;
        const vip = this.vipMics || 1;
        return total - vip;
      }
    },
    autoArrangement: { type: Boolean, default: true }, // ترتيب تلقائي عند التغيير
    micLayout: {
      type: String,
      enum: ['grid', 'circle', 'rows', 'custom'],
      default: function() {
        const total = this.totalMics || 6;
        if (total <= 6) return 'circle';
        if (total <= 12) return 'grid';
        return 'rows';
      }
    },
    micPermissions: {
      requireApprovalToSpeak: { type: Boolean, default: false },
      autoMuteNewSpeakers: { type: Boolean, default: false },
      allowSelfMute: { type: Boolean, default: true },
      allowSelfUnmute: { type: Boolean, default: true },
      priorityQueue: { type: Boolean, default: true } // أولوية للمدراء في الطابور
    },
    // تخطيط المايكات حسب العدد
    layoutConfig: {
      type: Map,
      of: {
        rows: Number,
        cols: Number,
        vipPositions: [Number], // مواقع مايكات VIP
        guestPositions: [Number] // مواقع مايكات الضيوف
      },
      default: function() {
        const configs = new Map();
        
        // تخطيط 2 مايك
        configs.set('2', {
          rows: 1,
          cols: 2,
          vipPositions: [],
          guestPositions: [1, 2]
        });
        
        // تخطيط 6 مايك
        configs.set('6', {
          rows: 2,
          cols: 3,
          vipPositions: [1],
          guestPositions: [2, 3, 4, 5, 6]
        });
        
        // تخطيط 12 مايك
        configs.set('12', {
          rows: 3,
          cols: 4,
          vipPositions: [1, 2],
          guestPositions: [3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
        });
        
        // تخطيط 16 مايك
        configs.set('16', {
          rows: 4,
          cols: 4,
          vipPositions: [1, 2, 3],
          guestPositions: [4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16]
        });
        
        // تخطيط 20 مايك
        configs.set('20', {
          rows: 4,
          cols: 5,
          vipPositions: [1, 2, 3, 4],
          guestPositions: [5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
        });
        
        return configs;
      }
    }
  }
});

// نموذج الغرفة الصوتية
const roomSchema = new mongoose.Schema({
  // معلومات أساسية
  roomId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  title: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  description: {
    type: String,
    trim: true,
    maxlength: 500
  },
  category: {
    type: String,
    required: true,
    enum: ['عام', 'تقنية', 'ثقافة', 'رياضة', 'موسيقى', 'ألعاب', 'تعليم', 'أخرى']
  },
  tags: [{
    type: String,
    trim: true,
    maxlength: 20
  }],
  
  // مالك الغرفة
  ownerId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  
  // المدراء
  admins: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    assignedAt: {
      type: Date,
      default: Date.now
    },
    assignedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    permissions: {
      canKick: { type: Boolean, default: true },
      canMute: { type: Boolean, default: true },
      canManageSeats: { type: Boolean, default: true },
      canManageChat: { type: Boolean, default: false },
      canManageMusic: { type: Boolean, default: false },
      canInviteUsers: { type: Boolean, default: true }
    }
  }],
  
  // المحظورين
  bannedUsers: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    bannedAt: {
      type: Date,
      default: Date.now
    },
    bannedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    reason: {
      type: String,
      maxlength: 200
    },
    expiresAt: {
      type: Date,
      default: null // null = حظر دائم
    }
  }],
  
  // المقاعد
  seats: [seatSchema],
  
  // طابور الانتظار
  waitingQueue: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    requestedAt: {
      type: Date,
      default: Date.now
    },
    priority: {
      type: Number,
      default: 0 // أعلى رقم = أولوية أعلى
    }
  }],
  
  // المستخدمين المتصلين (المستمعين)
  listeners: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    joinedAt: {
      type: Date,
      default: Date.now
    },
    lastSeen: {
      type: Date,
      default: Date.now
    }
  }],
  
  // الدعوات المرسلة
  invitations: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    invitedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    invitedAt: {
      type: Date,
      default: Date.now
    },
    status: {
      type: String,
      enum: ['pending', 'accepted', 'declined', 'expired'],
      default: 'pending'
    },
    expiresAt: {
      type: Date,
      default: () => new Date(Date.now() + 24 * 60 * 60 * 1000) // 24 ساعة
    }
  }],
  
  // إعدادات الغرفة
  settings: roomSettingsSchema,
  
  // حالة الغرفة
  status: {
    type: String,
    enum: ['active', 'paused', 'ended', 'scheduled'],
    default: 'active'
  },
  
  // إحصائيات
  stats: {
    totalJoins: { type: Number, default: 0 },
    totalMessages: { type: Number, default: 0 },
    totalDuration: { type: Number, default: 0 }, // بالدقائق
    peakParticipants: { type: Number, default: 0 },
    lastActivity: { type: Date, default: Date.now }
  },
  
  // معلومات الجدولة (للغرف المجدولة)
  schedule: {
    startTime: { type: Date, default: null },
    endTime: { type: Date, default: null },
    isRecurring: { type: Boolean, default: false },
    recurringPattern: {
      type: String,
      enum: ['daily', 'weekly', 'monthly'],
      default: null
    }
  },
  
  // تواريخ مهمة
  createdAt: {
    type: Date,
    default: Date.now,
    index: true
  },
  updatedAt: {
    type: Date,
    default: Date.now
  },
  lastActiveAt: {
    type: Date,
    default: Date.now
  }
}, {
  timestamps: true
});

// فهارس للأداء
roomSchema.index({ ownerId: 1, createdAt: -1 });
roomSchema.index({ category: 1, status: 1 });
roomSchema.index({ 'settings.accessSettings.isPrivate': 1, status: 1 });
roomSchema.index({ lastActiveAt: -1 });
roomSchema.index({ 'stats.peakParticipants': -1 });

// Middleware لتحديث updatedAt
roomSchema.pre('save', function(next) {
  this.updatedAt = new Date();
  next();
});

// Methods للغرفة
roomSchema.methods = {
  // التحقق من صلاحيات المستخدم
  getUserRole(userId) {
    const userIdStr = userId.toString();
    
    if (this.ownerId.toString() === userIdStr) {
      return 'owner';
    }
    
    const admin = this.admins.find(admin => admin.userId.toString() === userIdStr);
    if (admin) {
      return 'admin';
    }
    
    const seat = this.seats.find(seat => seat.userId && seat.userId.toString() === userIdStr);
    if (seat) {
      return 'speaker';
    }
    
    const listener = this.listeners.find(listener => listener.userId.toString() === userIdStr);
    if (listener) {
      return 'listener';
    }
    
    return 'guest';
  },
  
  // التحقق من الصلاحيات
  hasPermission(userId, permission) {
    const role = this.getUserRole(userId);
    
    if (role === 'owner') {
      return true; // المالك له جميع الصلاحيات
    }
    
    if (role === 'admin') {
      const admin = this.admins.find(admin => admin.userId.toString() === userId.toString());
      return admin && admin.permissions[permission];
    }
    
    return false;
  },
  
  // إضافة مستخدم للمقعد
  addUserToSeat(userId, seatNumber) {
    const seat = this.seats.find(s => s.seatNumber === seatNumber);
    if (seat && !seat.userId) {
      seat.userId = userId;
      seat.joinedAt = new Date();
      return true;
    }
    return false;
  },
  
  // إزالة مستخدم من المقعد
  removeUserFromSeat(userId) {
    const seat = this.seats.find(s => s.userId && s.userId.toString() === userId.toString());
    if (seat) {
      seat.userId = null;
      seat.joinedAt = null;
      seat.isMuted = false;
      return true;
    }
    return false;
  },
  
  // إضافة للطابور
  addToWaitingQueue(userId, priority = 0) {
    const existing = this.waitingQueue.find(q => q.userId.toString() === userId.toString());
    if (!existing) {
      this.waitingQueue.push({
        userId,
        priority,
        requestedAt: new Date()
      });
      // ترتيب حسب الأولوية ثم الوقت
      this.waitingQueue.sort((a, b) => {
        if (a.priority !== b.priority) {
          return b.priority - a.priority;
        }
        return a.requestedAt - b.requestedAt;
      });
      return true;
    }
    return false;
  },
  
  // إزالة من الطابور
  removeFromWaitingQueue(userId) {
    const index = this.waitingQueue.findIndex(q => q.userId.toString() === userId.toString());
    if (index !== -1) {
      this.waitingQueue.splice(index, 1);
      return true;
    }
    return false;
  },
  
  // التحقق من الحظر
  isUserBanned(userId) {
    const ban = this.bannedUsers.find(b => 
      b.userId.toString() === userId.toString() && 
      (!b.expiresAt || b.expiresAt > new Date())
    );
    return !!ban;
  },
  
  // حظر مستخدم
  banUser(userId, bannedBy, reason, duration = null) {
    if (this.isUserBanned(userId)) {
      return false;
    }
    
    const expiresAt = duration ? new Date(Date.now() + duration) : null;
    
    this.bannedUsers.push({
      userId,
      bannedBy,
      reason,
      expiresAt,
      bannedAt: new Date()
    });
    
    // إزالة من المقعد والطابور والمستمعين
    this.removeUserFromSeat(userId);
    this.removeFromWaitingQueue(userId);
    this.listeners = this.listeners.filter(l => l.userId.toString() !== userId.toString());
    
    return true;
  },
  
  // إلغاء الحظر
  unbanUser(userId) {
    const index = this.bannedUsers.findIndex(b => b.userId.toString() === userId.toString());
    if (index !== -1) {
      this.bannedUsers.splice(index, 1);
      return true;
    }
    return false;
  },
  
  // تغيير عدد المايكات
  changeMicCount(newCount, autoArrange = true) {
    if (![2, 6, 12, 16, 20].includes(newCount)) {
      throw new Error('عدد المايكات يجب أن يكون 2، 6، 12، 16، أو 20');
    }
    
    const oldCount = this.settings.micSettings.totalMics;
    this.settings.micSettings.totalMics = newCount;
    
    // تحديث عدد مايكات VIP
    if (newCount === 2) this.settings.micSettings.vipMics = 0;
    else if (newCount === 6) this.settings.micSettings.vipMics = 1;
    else if (newCount === 12) this.settings.micSettings.vipMics = 2;
    else if (newCount === 16) this.settings.micSettings.vipMics = 3;
    else if (newCount === 20) this.settings.micSettings.vipMics = 4;
    
    this.settings.micSettings.guestMics = newCount - this.settings.micSettings.vipMics;
    
    // إعادة ترتيب المقاعد إذا لزم الأمر
    if (autoArrange) {
      this.rearrangeSeats(newCount);
    }
    
    return true;
  },
  
  // إعادة ترتيب المقاعد
  rearrangeSeats(newMicCount) {
    const currentSeats = [...this.seats];
    
    // إنشاء مقاعد جديدة
    this.seats = [];
    for (let i = 1; i <= newMicCount; i++) {
      const isVIP = i <= this.settings.micSettings.vipMics;
      this.seats.push({
        seatNumber: i,
        userId: null,
        isVIP: isVIP,
        isMuted: false,
        isLocked: false,
        joinedAt: null
      });
    }
    
    // إعادة توزيع المستخدمين الموجودين
    const occupiedSeats = currentSeats.filter(seat => seat.userId);
    
    // أولاً: وضع المدراء في مقاعد VIP
    const adminUsers = occupiedSeats.filter(seat => {
      const userId = seat.userId.toString();
      return this.admins.some(admin => admin.userId.toString() === userId) || 
             this.ownerId.toString() === userId;
    });
    
    let vipSeatIndex = 0;
    adminUsers.forEach(adminSeat => {
      if (vipSeatIndex < this.settings.micSettings.vipMics) {
        this.seats[vipSeatIndex].userId = adminSeat.userId;
        this.seats[vipSeatIndex].joinedAt = adminSeat.joinedAt;
        this.seats[vipSeatIndex].isMuted = adminSeat.isMuted;
        vipSeatIndex++;
      }
    });
    
    // ثانياً: وضع باقي المستخدمين في المقاعد المتاحة
    const regularUsers = occupiedSeats.filter(seat => {
      const userId = seat.userId.toString();
      return !this.admins.some(admin => admin.userId.toString() === userId) && 
             this.ownerId.toString() !== userId;
    });
    
    let regularSeatIndex = this.settings.micSettings.vipMics;
    regularUsers.forEach(userSeat => {
      if (regularSeatIndex < newMicCount) {
        this.seats[regularSeatIndex].userId = userSeat.userId;
        this.seats[regularSeatIndex].joinedAt = userSeat.joinedAt;
        this.seats[regularSeatIndex].isMuted = userSeat.isMuted;
        regularSeatIndex++;
      } else {
        // إضافة للطابور إذا لم تعد هناك مقاعد
        this.addToWaitingQueue(userSeat.userId, 1); // أولوية عالية للمستخدمين المطرودين
      }
    });
  },
  
  // الحصول على تخطيط المايكات
  getMicLayout() {
    const totalMics = this.settings.micSettings.totalMics;
    const layouts = {
      2: { rows: 1, cols: 2, type: 'horizontal' },
      6: { rows: 2, cols: 3, type: 'grid' },
      12: { rows: 3, cols: 4, type: 'grid' },
      16: { rows: 4, cols: 4, type: 'square' },
      20: { rows: 4, cols: 5, type: 'grid' }
    };
    
    return layouts[totalMics] || layouts[6];
  },
  
  // التحقق من إمكانية تغيير عدد المايكات
  canChangeMicCount(userId, newCount) {
    // فقط المالك يمكنه تغيير عدد المايكات
    if (this.ownerId.toString() !== userId.toString()) {
      return { allowed: false, reason: 'فقط مالك الغرفة يمكنه تغيير عدد المايكات' };
    }
    
    if (![2, 6, 12, 16, 20].includes(newCount)) {
      return { allowed: false, reason: 'عدد المايكات يجب أن يكون 2، 6، 12، 16، أو 20' };
    }
    
    const currentOccupied = this.seats.filter(s => s.userId).length;
    if (newCount < currentOccupied) {
      return { 
        allowed: true, 
        warning: `سيتم نقل ${currentOccupied - newCount} مستخدم إلى طابور الانتظار` 
      };
    }
    
    return { allowed: true };
  },
  
  // الحصول على إحصائيات المايكات
  getMicStats() {
    const totalMics = this.settings.micSettings.totalMics;
    const occupiedMics = this.seats.filter(s => s.userId).length;
    const vipMics = this.settings.micSettings.vipMics;
    const occupiedVipMics = this.seats.slice(0, vipMics).filter(s => s.userId).length;
    const mutedMics = this.seats.filter(s => s.userId && s.isMuted).length;
    
    return {
      total: totalMics,
      occupied: occupiedMics,
      available: totalMics - occupiedMics,
      vip: {
        total: vipMics,
        occupied: occupiedVipMics,
        available: vipMics - occupiedVipMics
      },
      guest: {
        total: totalMics - vipMics,
        occupied: occupiedMics - occupiedVipMics,
        available: (totalMics - vipMics) - (occupiedMics - occupiedVipMics)
      },
      muted: mutedMics,
      waitingQueue: this.waitingQueue.length
    };
  },
  
  // الحصول على عدد المشاركين الحاليين
  getCurrentParticipantCount() {
    const speakersCount = this.seats.filter(s => s.userId).length;
    const listenersCount = this.listeners.length;
    return speakersCount + listenersCount;
  },
  
  // تحديث ذروة المشاركين
  updatePeakParticipants() {
    const currentCount = this.getCurrentParticipantCount();
    if (currentCount > this.stats.peakParticipants) {
      this.stats.peakParticipants = currentCount;
    }
  }
};

// Static methods
roomSchema.statics = {
  // البحث عن الغرف النشطة
  findActiveRooms(filters = {}) {
    const query = { status: 'active', ...filters };
    return this.find(query)
      .populate('ownerId', 'displayName profilePicture')
      .populate('seats.userId', 'displayName profilePicture')
      .sort({ lastActiveAt: -1 });
  },
  
  // البحث عن غرف المستخدم
  findUserRooms(userId) {
    return this.find({
      $or: [
        { ownerId: userId },
        { 'admins.userId': userId },
        { 'seats.userId': userId },
        { 'listeners.userId': userId }
      ]
    }).populate('ownerId', 'displayName profilePicture');
  },
  
  // تنظيف الغرف القديمة
  cleanupInactiveRooms(hoursInactive = 24) {
    const cutoffDate = new Date(Date.now() - hoursInactive * 60 * 60 * 1000);
    return this.updateMany(
      { 
        lastActiveAt: { $lt: cutoffDate },
        status: 'active'
      },
      { 
        status: 'ended',
        updatedAt: new Date()
      }
    );
  }
};

module.exports = mongoose.model('Room', roomSchema);

