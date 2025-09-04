require('dotenv').config();
const fastify = require('fastify')({ logger: true });
const mongoose = require('mongoose');
const admin = require('firebase-admin');

// تهيئة Firebase Admin (يتطلب ملف serviceAccountKey.json)
try {
  const serviceAccount = require('./serviceAccountKey.json');
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });
  console.log('Firebase Admin initialized successfully');
} catch (error) {
  console.error('Firebase Admin initialization failed:', error.message);
  console.log('Please add your serviceAccountKey.json file to the backend directory');
}

// تسجيل CORS
fastify.register(require('@fastify/cors'), {
  origin: true, // السماح لجميع المصادر
  credentials: true
});

// تسجيل خدمة الملفات الثابتة
fastify.register(require('@fastify/static'), {
  root: require('path').join(__dirname, 'uploads'),
  prefix: '/uploads/'
});

// middleware للمصادقة
fastify.decorate('authenticate', async function (request, reply) {
  try {
    const token = request.headers.authorization?.replace('Bearer ', '');
    if (!token) {
      throw new Error('Token مطلوب');
    }

    const decodedToken = await admin.auth().verifyIdToken(token);
    request.user = decodedToken;
  } catch (error) {
    reply.status(401).send({ error: 'غير مصرح', message: error.message });
  }
});

// استيراد وتسجيل مسارات API
const authRoutes = require('./routes/auth.js');
const splashRoutes = require('./routes/splash.js');
const profanityRoutes = require('./routes/profanity.js');
const mediaRoutes = require('./routes/media.js');
const uploadRoutes = require('./routes/upload.js');

fastify.register(authRoutes, { prefix: '/api/auth' });
fastify.register(splashRoutes, { prefix: '/api/splash' });
fastify.register(profanityRoutes, { prefix: '/api/profanity' });
fastify.register(mediaRoutes, { prefix: '/api/media' });
fastify.register(uploadRoutes, { prefix: '/api/upload' });

// نقطة وصول تجريبية للتأكد من عمل الخادم
fastify.get('/', async (request, reply) => {
    return { 
        message: 'HUS Backend Server is running!',
        version: '1.0.0',
        status: 'active'
    };
});

// نقطة وصول للتحقق من حالة قاعدة البيانات
fastify.get('/health', async (request, reply) => {
    const dbState = mongoose.connection.readyState;
    let dbStatus = 'disconnected';
    
    switch(dbState) {
        case 1: dbStatus = 'connected'; break;
        case 2: dbStatus = 'connecting'; break;
        case 3: dbStatus = 'disconnecting'; break;
        default: dbStatus = 'disconnected';
    }
    
    return {
        server: 'healthy',
        database: dbStatus,
        firebase: admin.apps.length > 0 ? 'initialized' : 'not initialized',
        timestamp: new Date().toISOString()
    };
});

// دالة بدء تشغيل الخادم
const start = async () => {
    try {
        // الاتصال بقاعدة البيانات
        if (!process.env.MONGO_URI) {
            throw new Error('MONGO_URI environment variable is required');
        }
        
        await mongoose.connect(process.env.MONGO_URI);
        fastify.log.info('Connected to MongoDB successfully');

        // تشغيل الخادم
        await fastify.listen({ port: 3000, host: '0.0.0.0' });
        fastify.log.info('Server is running on http://localhost:3000');

    } catch (err) {
        fastify.log.error(err);
        process.exit(1);
    }
};

start();

