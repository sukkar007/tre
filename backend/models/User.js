const mongoose = require('mongoose');
const { nanoid } = require('nanoid');

const userSchema = new mongoose.Schema({
    // المعرّف المخصص للتطبيق
    userId: {
        type: String,
        required: true,
        unique: true,
        index: true,
        default: () => nanoid(10)
    },

    // معرّف Firebase للربط والمصادقة
    firebaseUid: {
        type: String,
        required: true,
        unique: true,
        index: true
    },

    // معلومات الاتصال
    email: {
        type: String,
        required: false,
        unique: true,
        sparse: true
    },
    phoneNumber: {
        type: String,
        required: false,
        unique: true,
        sparse: true
    },

    // معلومات الملف الشخصي
    displayName: {
        type: String,
        required: true
    },
    photoURL: {
        type: String,
        required: false,
        default: 'https://via.placeholder.com/150/cccccc/ffffff?text=User'
    },

    // معلومات الأمان
    deviceIds: [{
        type: String,
        required: true
    }],
    isBanned: {
        type: Boolean,
        default: false
    },

    // معلومات النشاط
    lastLogin: {
        type: Date,
        default: Date.now
    },
    isOnline: {
        type: Boolean,
        default: false
    }
}, {
    timestamps: true // يضيف createdAt و updatedAt تلقائياً
});

// فهرسة للبحث السريع
userSchema.index({ userId: 1 });
userSchema.index({ firebaseUid: 1 });
userSchema.index({ email: 1 });
userSchema.index({ phoneNumber: 1 });

// دالة مساعدة للحصول على بيانات المستخدم العامة (بدون معلومات حساسة)
userSchema.methods.getPublicProfile = function() {
    return {
        userId: this.userId,
        displayName: this.displayName,
        photoURL: this.photoURL,
        isOnline: this.isOnline,
        createdAt: this.createdAt
    };
};

module.exports = mongoose.model('User', userSchema);

