const mongoose = require('mongoose');

// نموذج رسائل الغرفة الصوتية
const roomMessageSchema = new mongoose.Schema({
  // معرف الرسالة
  messageId: {
    type: String,
    required: true,
    unique: true,
    index: true
  },
  
  // الغرفة التي تنتمي إليها الرسالة
  roomId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Room',
    required: true,
    index: true
  },
  
  // المرسل
  senderId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
    index: true
  },
  
  // معلومات المرسل (محفوظة للعرض السريع)
  senderInfo: {
    displayName: {
      type: String,
      required: true,
      trim: true
    },
    profilePicture: {
      type: String,
      default: null
    },
    role: {
      type: String,
      enum: ['owner', 'admin', 'speaker', 'listener', 'guest'],
      default: 'listener'
    },
    // شارات خاصة
    badges: [{
      type: String,
      enum: ['verified', 'vip', 'supporter', 'moderator', 'new_user']
    }],
    // لون مخصص للاسم (للمدراء والمالك)
    nameColor: {
      type: String,
      default: '#333333'
    }
  },
  
  // المستخدم المستهدف (للرسائل النظام)
  targetUserId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null
  },
  
  // معلومات المستخدم المستهدف
  targetUserInfo: {
    displayName: String,
    profilePicture: String,
    role: String
  },
  
  // نوع الرسالة
  messageType: {
    type: String,
    enum: [
      'text',           // رسالة نصية
      'emoji',          // إيموجي
      'image',          // صورة
      'audio',          // رسالة صوتية
      'system',         // رسالة نظام
      'system_join',    // رسالة انضمام مستخدم
      'system_leave',   // رسالة مغادرة مستخدم
      'system_mic_join', // انتقال للمايك
      'system_mic_leave', // مغادرة المايك
      'system_mute',    // كتم مستخدم
      'system_unmute',  // إلغاء كتم
      'system_kick',    // طرد مستخدم
      'system_admin',   // تعيين مدير
      'system_settings', // تغيير إعدادات
      'gift',           // هدية
      'announcement'    // إعلان
    ],
    default: 'text'
  },
  
  // محتوى الرسالة
  content: {
    // النص الأساسي
    text: {
      type: String,
      maxlength: 500,
      trim: true
    },
    
    // الملفات المرفقة
    attachments: [{
      type: {
        type: String,
        enum: ['image', 'audio', 'file']
      },
      url: String,
      filename: String,
      size: Number, // بالبايت
      duration: Number // للملفات الصوتية (بالثواني)
    }],
    
    // الإيموجي أو الهدايا
    emoji: {
      code: String,
      name: String,
      category: String
    },
    
    // معلومات إضافية للرسائل الخاصة
    metadata: {
      type: Map,
      of: mongoose.Schema.Types.Mixed
    }
  },
  
  // الرد على رسالة أخرى
  replyTo: {
    messageId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'RoomMessage'
    },
    senderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    preview: {
      type: String,
      maxlength: 100
    }
  },
  
  // المنشن (الإشارة لمستخدمين)
  mentions: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    displayName: String,
    position: {
      start: Number,
      end: Number
    }
  }],
  
  // التفاعلات مع الرسالة
  reactions: [{
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    emoji: String,
    createdAt: {
      type: Date,
      default: Date.now
    }
  }],
  
  // حالة الرسالة
  status: {
    type: String,
    enum: ['sent', 'delivered', 'read', 'deleted', 'edited', 'filtered'],
    default: 'sent'
  },
  
  // معلومات التعديل
  editHistory: [{
    originalContent: String,
    editedAt: Date,
    editedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    }
  }],
  
  // معلومات الحذف
  deletedInfo: {
    deletedAt: Date,
    deletedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    reason: String,
    isHidden: { type: Boolean, default: false } // مخفية أم محذوفة نهائياً
  },
  
  // فلترة المحتوى
  contentFilter: {
    isFiltered: { type: Boolean, default: false },
    filteredWords: [String],
    severity: {
      type: String,
      enum: ['low', 'medium', 'high'],
      default: 'low'
    },
    action: {
      type: String,
      enum: ['warn', 'censor', 'block', 'delete'],
      default: 'warn'
    }
  },
  
  // معلومات الإبلاغ
  reports: [{
    reportedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    reason: {
      type: String,
      enum: ['spam', 'harassment', 'inappropriate', 'hate_speech', 'other']
    },
    description: String,
    reportedAt: {
      type: Date,
      default: Date.now
    },
    status: {
      type: String,
      enum: ['pending', 'reviewed', 'resolved', 'dismissed'],
      default: 'pending'
    }
  }],
  
  // الأولوية (للرسائل المهمة)
  priority: {
    type: String,
    enum: ['low', 'normal', 'high', 'urgent'],
    default: 'normal'
  },
  
  // معلومات الجهاز والموقع
  deviceInfo: {
    platform: String, // android, ios, web
    version: String,
    userAgent: String,
    ipAddress: String
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
  expiresAt: {
    type: Date,
    default: null // للرسائل المؤقتة
  }
}, {
  timestamps: true
});

// فهارس للأداء
roomMessageSchema.index({ roomId: 1, createdAt: -1 });
roomMessageSchema.index({ senderId: 1, createdAt: -1 });
roomMessageSchema.index({ messageType: 1, status: 1 });
roomMessageSchema.index({ 'contentFilter.isFiltered': 1, 'contentFilter.severity': 1 });
roomMessageSchema.index({ 'reports.status': 1 });
roomMessageSchema.index({ expiresAt: 1 }, { expireAfterSeconds: 0 });

// Middleware لتحديث updatedAt
roomMessageSchema.pre('save', function(next) {
  this.updatedAt = new Date();
  next();
});

// Methods للرسالة
roomMessageSchema.methods = {
  // التحقق من إمكانية التعديل
  canEdit(userId, timeLimit = 300) { // 5 دقائق افتراضياً
    if (this.senderId.toString() !== userId.toString()) {
      return false;
    }
    
    if (this.status === 'deleted') {
      return false;
    }
    
    const timeDiff = (Date.now() - this.createdAt.getTime()) / 1000;
    return timeDiff <= timeLimit;
  },
  
  // التحقق من إمكانية الحذف
  canDelete(userId, userRole = 'user') {
    // المرسل يمكنه الحذف دائماً
    if (this.senderId.toString() === userId.toString()) {
      return true;
    }
    
    // المدراء والمالك يمكنهم الحذف
    return ['admin', 'owner'].includes(userRole);
  },
  
  // إضافة تفاعل
  addReaction(userId, emoji) {
    // إزالة التفاعل السابق للمستخدم
    this.reactions = this.reactions.filter(r => r.userId.toString() !== userId.toString());
    
    // إضافة التفاعل الجديد
    this.reactions.push({
      userId,
      emoji,
      createdAt: new Date()
    });
    
    return this.save();
  },
  
  // إزالة تفاعل
  removeReaction(userId) {
    this.reactions = this.reactions.filter(r => r.userId.toString() !== userId.toString());
    return this.save();
  },
  
  // تعديل الرسالة
  editMessage(newContent, editedBy) {
    if (!this.canEdit(editedBy)) {
      throw new Error('لا يمكن تعديل هذه الرسالة');
    }
    
    // حفظ المحتوى الأصلي في التاريخ
    this.editHistory.push({
      originalContent: this.content.text,
      editedAt: new Date(),
      editedBy
    });
    
    // تحديث المحتوى
    this.content.text = newContent;
    this.status = 'edited';
    
    return this.save();
  },
  
  // حذف الرسالة
  deleteMessage(deletedBy, reason = '', isHidden = false) {
    this.status = 'deleted';
    this.deletedInfo = {
      deletedAt: new Date(),
      deletedBy,
      reason,
      isHidden
    };
    
    if (!isHidden) {
      this.content.text = '[تم حذف هذه الرسالة]';
      this.content.attachments = [];
    }
    
    return this.save();
  },
  
  // إبلاغ عن الرسالة
  reportMessage(reportedBy, reason, description = '') {
    // التحقق من عدم الإبلاغ المسبق
    const existingReport = this.reports.find(r => 
      r.reportedBy.toString() === reportedBy.toString() && 
      r.status === 'pending'
    );
    
    if (existingReport) {
      throw new Error('لقد قمت بالإبلاغ عن هذه الرسالة مسبقاً');
    }
    
    this.reports.push({
      reportedBy,
      reason,
      description,
      reportedAt: new Date(),
      status: 'pending'
    });
    
    return this.save();
  },
  
  // فلترة المحتوى
  filterContent(filteredWords, severity = 'low', action = 'warn') {
    this.contentFilter = {
      isFiltered: true,
      filteredWords,
      severity,
      action
    };
    
    if (action === 'censor') {
      // استبدال الكلمات السيئة بنجوم
      let filteredText = this.content.text;
      filteredWords.forEach(word => {
        const regex = new RegExp(word, 'gi');
        filteredText = filteredText.replace(regex, '*'.repeat(word.length));
      });
      this.content.text = filteredText;
    } else if (action === 'block' || action === 'delete') {
      this.status = 'filtered';
    }
    
    return this.save();
  },
  
  // الحصول على معاينة الرسالة
  getPreview(maxLength = 100) {
    if (this.status === 'deleted') {
      return '[تم حذف هذه الرسالة]';
    }
    
    if (this.messageType === 'text') {
      const text = this.content.text || '';
      return text.length > maxLength ? text.substring(0, maxLength) + '...' : text;
    } else if (this.messageType === 'image') {
      return '📷 صورة';
    } else if (this.messageType === 'audio') {
      return '🎵 رسالة صوتية';
    } else if (this.messageType === 'emoji') {
      return this.content.emoji?.name || '😊';
    }
    
    return 'رسالة';
  }
};

// Static methods
roomMessageSchema.statics = {
  // إنشاء رسالة انضمام
  createJoinMessage(roomId, user) {
    const messageId = `${roomId}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    return this.create({
      messageId,
      roomId,
      senderId: user._id,
      messageType: 'system_join',
      senderInfo: {
        displayName: user.displayName,
        profilePicture: user.profilePicture,
        role: 'listener',
        nameColor: '#10B981' // أخضر للانضمام
      },
      content: {
        text: `انضم إلى الغرفة`,
        metadata: new Map([
          ['action', 'join'],
          ['timestamp', new Date().toISOString()]
        ])
      },
      priority: 'normal'
    });
  },
  
  // إنشاء رسالة مغادرة
  createLeaveMessage(roomId, user) {
    const messageId = `${roomId}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    return this.create({
      messageId,
      roomId,
      senderId: user._id,
      messageType: 'system_leave',
      senderInfo: {
        displayName: user.displayName,
        profilePicture: user.profilePicture,
        role: user.role || 'listener',
        nameColor: '#EF4444' // أحمر للمغادرة
      },
      content: {
        text: `غادر الغرفة`,
        metadata: new Map([
          ['action', 'leave'],
          ['timestamp', new Date().toISOString()]
        ])
      },
      priority: 'normal'
    });
  },
  
  // إنشاء رسالة انتقال للمايك
  createMicJoinMessage(roomId, user, seatNumber) {
    const messageId = `${roomId}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    return this.create({
      messageId,
      roomId,
      senderId: user._id,
      messageType: 'system_mic_join',
      senderInfo: {
        displayName: user.displayName,
        profilePicture: user.profilePicture,
        role: 'speaker',
        nameColor: '#8B5CF6' // بنفسجي للمايك
      },
      content: {
        text: `انتقل إلى المايك ${seatNumber}`,
        metadata: new Map([
          ['action', 'mic_join'],
          ['seatNumber', seatNumber],
          ['timestamp', new Date().toISOString()]
        ])
      },
      priority: 'high'
    });
  },
  
  // إنشاء رسالة مغادرة المايك
  createMicLeaveMessage(roomId, user, seatNumber) {
    const messageId = `${roomId}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    return this.create({
      messageId,
      roomId,
      senderId: user._id,
      messageType: 'system_mic_leave',
      senderInfo: {
        displayName: user.displayName,
        profilePicture: user.profilePicture,
        role: 'listener',
        nameColor: '#6B7280' // رمادي للمغادرة
      },
      content: {
        text: `غادر المايك ${seatNumber}`,
        metadata: new Map([
          ['action', 'mic_leave'],
          ['seatNumber', seatNumber],
          ['timestamp', new Date().toISOString()]
        ])
      },
      priority: 'normal'
    });
  },
  
  // إنشاء رسالة كتم
  createMuteMessage(roomId, moderator, targetUser) {
    const messageId = `${roomId}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    return this.create({
      messageId,
      roomId,
      senderId: moderator._id,
      targetUserId: targetUser._id,
      messageType: 'system_mute',
      senderInfo: {
        displayName: moderator.displayName,
        profilePicture: moderator.profilePicture,
        role: moderator.role || 'admin',
        nameColor: '#F59E0B' // برتقالي للإجراءات الإدارية
      },
      targetUserInfo: {
        displayName: targetUser.displayName,
        profilePicture: targetUser.profilePicture,
        role: targetUser.role || 'speaker'
      },
      content: {
        text: `تم كتم ${targetUser.displayName}`,
        metadata: new Map([
          ['action', 'mute'],
          ['moderatorId', moderator._id.toString()],
          ['targetId', targetUser._id.toString()],
          ['timestamp', new Date().toISOString()]
        ])
      },
      priority: 'high'
    });
  },
  
  // إنشاء رسالة طرد
  createKickMessage(roomId, moderator, targetUser, reason = '') {
    const messageId = `${roomId}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    return this.create({
      messageId,
      roomId,
      senderId: moderator._id,
      targetUserId: targetUser._id,
      messageType: 'system_kick',
      senderInfo: {
        displayName: moderator.displayName,
        profilePicture: moderator.profilePicture,
        role: moderator.role || 'admin',
        nameColor: '#DC2626' // أحمر للطرد
      },
      targetUserInfo: {
        displayName: targetUser.displayName,
        profilePicture: targetUser.profilePicture,
        role: targetUser.role || 'listener'
      },
      content: {
        text: `تم طرد ${targetUser.displayName}${reason ? ` - ${reason}` : ''}`,
        metadata: new Map([
          ['action', 'kick'],
          ['moderatorId', moderator._id.toString()],
          ['targetId', targetUser._id.toString()],
          ['reason', reason],
          ['timestamp', new Date().toISOString()]
        ])
      },
      priority: 'urgent'
    });
  },
  
  // إنشاء رسالة تعيين مدير
  createAdminMessage(roomId, owner, newAdmin) {
    const messageId = `${roomId}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    return this.create({
      messageId,
      roomId,
      senderId: owner._id,
      targetUserId: newAdmin._id,
      messageType: 'system_admin',
      senderInfo: {
        displayName: owner.displayName,
        profilePicture: owner.profilePicture,
        role: 'owner',
        nameColor: '#7C3AED' // بنفسجي للمالك
      },
      targetUserInfo: {
        displayName: newAdmin.displayName,
        profilePicture: newAdmin.profilePicture,
        role: 'admin'
      },
      content: {
        text: `تم تعيين ${newAdmin.displayName} كمدير`,
        metadata: new Map([
          ['action', 'admin_assign'],
          ['ownerId', owner._id.toString()],
          ['newAdminId', newAdmin._id.toString()],
          ['timestamp', new Date().toISOString()]
        ])
      },
      priority: 'high'
    });
  },
  
  // إنشاء رسالة عادية
  createTextMessage(roomId, user, text, replyTo = null) {
    const messageId = `${roomId}_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;
    
    // تحديد لون الاسم حسب الدور
    let nameColor = '#333333'; // افتراضي
    if (user.role === 'owner') nameColor = '#7C3AED';
    else if (user.role === 'admin') nameColor = '#F59E0B';
    else if (user.role === 'speaker') nameColor = '#8B5CF6';
    
    return this.create({
      messageId,
      roomId,
      senderId: user._id,
      messageType: 'text',
      senderInfo: {
        displayName: user.displayName,
        profilePicture: user.profilePicture,
        role: user.role || 'listener',
        badges: user.badges || [],
        nameColor
      },
      content: {
        text: text.trim(),
        metadata: new Map([
          ['timestamp', new Date().toISOString()]
        ])
      },
      replyTo,
      priority: 'normal'
    });
  },
  // الحصول على رسائل الغرفة
  getRoomMessages(roomId, page = 1, limit = 50, includeDeleted = false) {
    const query = { roomId };
    
    if (!includeDeleted) {
      query.status = { $ne: 'deleted' };
    }
    
    return this.find(query)
      .populate('senderId', 'displayName profilePicture')
      .populate('replyTo.senderId', 'displayName')
      .sort({ createdAt: -1 })
      .limit(limit)
      .skip((page - 1) * limit);
  },
  
  // البحث في الرسائل
  searchMessages(roomId, searchTerm, filters = {}) {
    const query = {
      roomId,
      status: { $ne: 'deleted' },
      'content.text': { $regex: searchTerm, $options: 'i' }
    };
    
    if (filters.senderId) {
      query.senderId = filters.senderId;
    }
    
    if (filters.messageType) {
      query.messageType = filters.messageType;
    }
    
    if (filters.dateFrom) {
      query.createdAt = { $gte: new Date(filters.dateFrom) };
    }
    
    if (filters.dateTo) {
      query.createdAt = { ...query.createdAt, $lte: new Date(filters.dateTo) };
    }
    
    return this.find(query)
      .populate('senderId', 'displayName profilePicture')
      .sort({ createdAt: -1 })
      .limit(100);
  },
  
  // تنظيف الرسائل القديمة
  cleanupOldMessages(roomId, daysOld = 30) {
    const cutoffDate = new Date(Date.now() - daysOld * 24 * 60 * 60 * 1000);
    return this.deleteMany({
      roomId,
      createdAt: { $lt: cutoffDate },
      status: { $in: ['deleted', 'filtered'] }
    });
  },
  
  // إحصائيات الرسائل
  getMessageStats(roomId, timeframe = '24h') {
    const timeframes = {
      '1h': 1 * 60 * 60 * 1000,
      '24h': 24 * 60 * 60 * 1000,
      '7d': 7 * 24 * 60 * 60 * 1000,
      '30d': 30 * 24 * 60 * 60 * 1000
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
          _id: null,
          totalMessages: { $sum: 1 },
          uniqueSenders: { $addToSet: '$senderId' },
          messageTypes: { $push: '$messageType' },
          filteredMessages: {
            $sum: { $cond: ['$contentFilter.isFiltered', 1, 0] }
          },
          reportedMessages: {
            $sum: { $cond: [{ $gt: [{ $size: '$reports' }, 0] }, 1, 0] }
          }
        }
      },
      {
        $project: {
          totalMessages: 1,
          uniqueSenders: { $size: '$uniqueSenders' },
          messageTypes: 1,
          filteredMessages: 1,
          reportedMessages: 1
        }
      }
    ]);
  }
};

module.exports = mongoose.model('RoomMessage', roomMessageSchema);

