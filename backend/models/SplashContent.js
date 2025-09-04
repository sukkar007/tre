const mongoose = require('mongoose');

const splashContentSchema = new mongoose.Schema({
    // معرّف فريد لمحتوى الشاشة
    contentId: {
        type: String,
        required: true,
        unique: true,
        default: 'default_splash'
    },

    // معلومات أساسية
    title: {
        type: String,
        required: true,
        default: 'مرحباً بك في HUS'
    },
    subtitle: {
        type: String,
        required: false,
        default: 'تطبيق الدردشة الصوتية الأول'
    },
    description: {
        type: String,
        required: false,
        default: 'انضم إلى آلاف المستخدمين في غرف الدردشة الصوتية'
    },

    // الصور والوسائط
    backgroundImage: {
        type: String,
        required: false,
        default: 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800'
    },
    logoImage: {
        type: String,
        required: false,
        default: 'https://via.placeholder.com/200x200/6366f1/ffffff?text=HUS'
    },

    // الألوان والتصميم
    primaryColor: {
        type: String,
        required: false,
        default: '#6366f1' // Indigo
    },
    secondaryColor: {
        type: String,
        required: false,
        default: '#8b5cf6' // Purple
    },
    textColor: {
        type: String,
        required: false,
        default: '#ffffff'
    },
    backgroundColor: {
        type: String,
        required: false,
        default: '#1f2937' // Dark gray
    },

    // إعدادات العرض
    displayDuration: {
        type: Number,
        required: false,
        default: 3000 // 3 ثوانٍ بالميلي ثانية
    },
    showProgressBar: {
        type: Boolean,
        default: true
    },
    animationType: {
        type: String,
        enum: ['fade', 'slide', 'zoom', 'none'],
        default: 'fade'
    },

    // الإعلانات (للمستقبل)
    advertisements: [{
        adId: String,
        title: String,
        description: String,
        imageUrl: String,
        actionUrl: String, // رابط عند الضغط على الإعلان
        displayOrder: {
            type: Number,
            default: 0
        },
        isActive: {
            type: Boolean,
            default: true
        },
        startDate: Date,
        endDate: Date
    }],

    // إعدادات الاستهداف
    targetAudience: {
        countries: [String], // قائمة الدول المستهدفة
        languages: [String], // قائمة اللغات
        appVersions: [String], // إصدارات التطبيق المدعومة
        platforms: {
            type: [String],
            enum: ['android', 'ios', 'web'],
            default: ['android', 'ios']
        }
    },

    // حالة المحتوى
    isActive: {
        type: Boolean,
        default: true
    },
    priority: {
        type: Number,
        default: 1 // أولوية العرض (الأعلى رقماً = أولوية أكبر)
    },

    // إحصائيات
    viewCount: {
        type: Number,
        default: 0
    },
    clickCount: {
        type: Number,
        default: 0
    },

    // تواريخ
    validFrom: {
        type: Date,
        default: Date.now
    },
    validUntil: {
        type: Date,
        default: () => new Date(Date.now() + 365 * 24 * 60 * 60 * 1000) // سنة من الآن
    }
}, {
    timestamps: true
});

// فهرسة للبحث السريع
splashContentSchema.index({ contentId: 1 });
splashContentSchema.index({ isActive: 1, priority: -1 });
splashContentSchema.index({ validFrom: 1, validUntil: 1 });

// دالة للحصول على المحتوى النشط
splashContentSchema.statics.getActiveContent = function(platform = 'android', country = null, language = null) {
    const now = new Date();
    const query = {
        isActive: true,
        validFrom: { $lte: now },
        validUntil: { $gte: now },
        'targetAudience.platforms': platform
    };

    // إضافة فلاتر إضافية إذا توفرت
    if (country) {
        query.$or = [
            { 'targetAudience.countries': { $size: 0 } }, // لا توجد قيود على الدول
            { 'targetAudience.countries': country }
        ];
    }

    if (language) {
        query.$or = query.$or || [];
        query.$or.push(
            { 'targetAudience.languages': { $size: 0 } }, // لا توجد قيود على اللغات
            { 'targetAudience.languages': language }
        );
    }

    return this.findOne(query).sort({ priority: -1, createdAt: -1 });
};

// دالة لزيادة عدد المشاهدات
splashContentSchema.methods.incrementViewCount = function() {
    this.viewCount += 1;
    return this.save();
};

// دالة لزيادة عدد النقرات
splashContentSchema.methods.incrementClickCount = function() {
    this.clickCount += 1;
    return this.save();
};

module.exports = mongoose.model('SplashContent', splashContentSchema);

