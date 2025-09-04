const admin = require('firebase-admin');
const jwt = require('jsonwebtoken');
const User = require('../models/User');

async function authRoutes(fastify, options) {

    // نقطة وصول تسجيل الدخول/التسجيل
    fastify.post('/login', async (request, reply) => {
        try {
            const { idToken, deviceId } = request.body;

            // التحقق من وجود البيانات المطلوبة
            if (!idToken || !deviceId) {
                return reply.status(400).send({ 
                    success: false,
                    message: 'idToken and deviceId are required.' 
                });
            }

            // التحقق من صحة idToken مع Firebase
            let decodedToken;
            try {
                decodedToken = await admin.auth().verifyIdToken(idToken);
            } catch (firebaseError) {
                return reply.status(401).send({ 
                    success: false,
                    message: 'Invalid Firebase token.',
                    error: firebaseError.message 
                });
            }

            const firebaseUid = decodedToken.uid;
            const email = decodedToken.email;
            const name = decodedToken.name || 'مستخدم جديد';
            const picture = decodedToken.picture;

            // البحث عن المستخدم في قاعدة البيانات
            let user = await User.findOne({ firebaseUid: firebaseUid });

            if (!user) {
                // إنشاء مستخدم جديد
                console.log(`Creating new user: ${name}`);
                user = new User({
                    firebaseUid: firebaseUid,
                    displayName: name,
                    email: email,
                    photoURL: picture,
                    deviceIds: [deviceId],
                    isOnline: true
                });
                await user.save();
                console.log(`New user created with userId: ${user.userId}`);
            } else {
                // تحديث بيانات المستخدم الحالي
                console.log(`User ${user.displayName} logged in with userId: ${user.userId}`);
                user.lastLogin = Date.now();
                user.isOnline = true;
                
                // إضافة معرّف الجهاز الجديد إذا لم يكن موجوداً
                if (!user.deviceIds.includes(deviceId)) {
                    user.deviceIds.push(deviceId);
                    console.log(`Added new device ID for user: ${user.userId}`);
                }
                
                // تحديث معلومات الملف الشخصي إذا تغيرت
                if (user.displayName !== name) user.displayName = name;
                if (user.email !== email) user.email = email;
                if (user.photoURL !== picture && picture) user.photoURL = picture;
                
                await user.save();
            }

            // التحقق من حالة الحظر
            if (user.isBanned) {
                return reply.status(403).send({ 
                    success: false,
                    message: 'Your account has been banned. Please contact support.' 
                });
            }

            // إنشاء توكن التطبيق (JWT)
            if (!process.env.JWT_SECRET) {
                throw new Error('JWT_SECRET environment variable is required');
            }

            const appToken = jwt.sign(
                { 
                    userId: user.userId, 
                    firebaseUid: user.firebaseUid,
                    deviceId: deviceId
                },
                process.env.JWT_SECRET,
                { expiresIn: '30d' }
            );

            // إرسال الرد الناجح
            reply.status(200).send({
                success: true,
                message: 'Login successful!',
                token: appToken,
                user: user.getPublicProfile()
            });

        } catch (error) {
            console.error("Login Error:", error);
            reply.status(500).send({ 
                success: false,
                message: 'Internal server error during authentication.',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    });

    // نقطة وصول تسجيل الخروج
    fastify.post('/logout', async (request, reply) => {
        try {
            // هنا يمكن إضافة منطق تسجيل الخروج مثل تحديث حالة isOnline
            // في الوقت الحالي، سنعتمد على انتهاء صلاحية التوكن من جهة العميل
            
            reply.status(200).send({
                success: true,
                message: 'Logout successful!'
            });
        } catch (error) {
            console.error("Logout Error:", error);
            reply.status(500).send({ 
                success: false,
                message: 'Error during logout.',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    });

    // نقطة وصول للتحقق من صحة التوكن
    fastify.get('/verify', async (request, reply) => {
        try {
            const authHeader = request.headers.authorization;
            if (!authHeader || !authHeader.startsWith('Bearer ')) {
                return reply.status(401).send({ 
                    success: false,
                    message: 'Authorization header is required.' 
                });
            }

            const token = authHeader.substring(7); // إزالة "Bearer "
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            
            // البحث عن المستخدم للتأكد من أنه لا يزال موجوداً وغير محظور
            const user = await User.findOne({ userId: decoded.userId });
            if (!user) {
                return reply.status(401).send({ 
                    success: false,
                    message: 'User not found.' 
                });
            }

            if (user.isBanned) {
                return reply.status(403).send({ 
                    success: false,
                    message: 'User is banned.' 
                });
            }

            reply.status(200).send({
                success: true,
                message: 'Token is valid.',
                user: user.getPublicProfile()
            });

        } catch (error) {
            if (error.name === 'JsonWebTokenError') {
                return reply.status(401).send({ 
                    success: false,
                    message: 'Invalid token.' 
                });
            }
            if (error.name === 'TokenExpiredError') {
                return reply.status(401).send({ 
                    success: false,
                    message: 'Token has expired.' 
                });
            }
            
            console.error("Token verification error:", error);
            reply.status(500).send({ 
                success: false,
                message: 'Error verifying token.',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    });
}

module.exports = authRoutes;

