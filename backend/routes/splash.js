const SplashContent = require('../models/SplashContent');

async function splashRoutes(fastify, options) {

    // الحصول على محتوى شاشة Splash
    fastify.get('/content', async (request, reply) => {
        try {
            const { platform = 'android', country, language, version } = request.query;

            // البحث عن المحتوى النشط المناسب
            let splashContent = await SplashContent.getActiveContent(platform, country, language);

            // إذا لم يوجد محتوى مخصص، إنشاء محتوى افتراضي
            if (!splashContent) {
                splashContent = await SplashContent.findOne({ contentId: 'default_splash' });
                
                // إنشاء محتوى افتراضي إذا لم يوجد
                if (!splashContent) {
                    splashContent = new SplashContent({
                        contentId: 'default_splash',
                        title: 'مرحباً بك في HUS',
                        subtitle: 'تطبيق الدردشة الصوتية الأول',
                        description: 'انضم إلى آلاف المستخدمين في غرف الدردشة الصوتية التفاعلية',
                        backgroundImage: 'https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800&q=80',
                        logoImage: 'https://via.placeholder.com/200x200/6366f1/ffffff?text=HUS',
                        primaryColor: '#6366f1',
                        secondaryColor: '#8b5cf6',
                        textColor: '#ffffff',
                        backgroundColor: '#1f2937',
                        displayDuration: 3000,
                        showProgressBar: true,
                        animationType: 'fade'
                    });
                    await splashContent.save();
                }
            }

            // زيادة عدد المشاهدات
            await splashContent.incrementViewCount();

            // تحضير البيانات للإرسال
            const responseData = {
                success: true,
                content: {
                    contentId: splashContent.contentId,
                    title: splashContent.title,
                    subtitle: splashContent.subtitle,
                    description: splashContent.description,
                    backgroundImage: splashContent.backgroundImage,
                    logoImage: splashContent.logoImage,
                    colors: {
                        primary: splashContent.primaryColor,
                        secondary: splashContent.secondaryColor,
                        text: splashContent.textColor,
                        background: splashContent.backgroundColor
                    },
                    settings: {
                        displayDuration: splashContent.displayDuration,
                        showProgressBar: splashContent.showProgressBar,
                        animationType: splashContent.animationType
                    },
                    advertisements: splashContent.advertisements.filter(ad => 
                        ad.isActive && 
                        (!ad.startDate || ad.startDate <= new Date()) &&
                        (!ad.endDate || ad.endDate >= new Date())
                    ).sort((a, b) => (b.displayOrder || 0) - (a.displayOrder || 0))
                },
                timestamp: new Date().toISOString()
            };

            reply.status(200).send(responseData);

        } catch (error) {
            console.error("Splash content error:", error);
            reply.status(500).send({ 
                success: false,
                message: 'Error fetching splash content.',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    });

    // تسجيل نقرة على إعلان
    fastify.post('/ad-click', async (request, reply) => {
        try {
            const { contentId, adId } = request.body;

            if (!contentId || !adId) {
                return reply.status(400).send({ 
                    success: false,
                    message: 'contentId and adId are required.' 
                });
            }

            const splashContent = await SplashContent.findOne({ contentId });
            if (!splashContent) {
                return reply.status(404).send({ 
                    success: false,
                    message: 'Splash content not found.' 
                });
            }

            // زيادة عدد النقرات
            await splashContent.incrementClickCount();

            reply.status(200).send({
                success: true,
                message: 'Ad click recorded successfully.'
            });

        } catch (error) {
            console.error("Ad click error:", error);
            reply.status(500).send({ 
                success: false,
                message: 'Error recording ad click.',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    });

    // إنشاء أو تحديث محتوى شاشة Splash (للإدارة)
    fastify.post('/content', async (request, reply) => {
        try {
            const contentData = request.body;

            // التحقق من البيانات المطلوبة
            if (!contentData.contentId) {
                return reply.status(400).send({ 
                    success: false,
                    message: 'contentId is required.' 
                });
            }

            // البحث عن محتوى موجود أو إنشاء جديد
            let splashContent = await SplashContent.findOne({ contentId: contentData.contentId });
            
            if (splashContent) {
                // تحديث المحتوى الموجود
                Object.assign(splashContent, contentData);
                await splashContent.save();
            } else {
                // إنشاء محتوى جديد
                splashContent = new SplashContent(contentData);
                await splashContent.save();
            }

            reply.status(200).send({
                success: true,
                message: 'Splash content saved successfully.',
                content: splashContent
            });

        } catch (error) {
            console.error("Save splash content error:", error);
            reply.status(500).send({ 
                success: false,
                message: 'Error saving splash content.',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    });

    // الحصول على قائمة جميع المحتويات (للإدارة)
    fastify.get('/admin/contents', async (request, reply) => {
        try {
            const { page = 1, limit = 10 } = request.query;
            const skip = (page - 1) * limit;

            const contents = await SplashContent.find()
                .sort({ priority: -1, createdAt: -1 })
                .skip(skip)
                .limit(parseInt(limit));

            const total = await SplashContent.countDocuments();

            reply.status(200).send({
                success: true,
                contents,
                pagination: {
                    page: parseInt(page),
                    limit: parseInt(limit),
                    total,
                    pages: Math.ceil(total / limit)
                }
            });

        } catch (error) {
            console.error("Get splash contents error:", error);
            reply.status(500).send({ 
                success: false,
                message: 'Error fetching splash contents.',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    });

    // حذف محتوى شاشة Splash (للإدارة)
    fastify.delete('/admin/content/:contentId', async (request, reply) => {
        try {
            const { contentId } = request.params;

            // منع حذف المحتوى الافتراضي
            if (contentId === 'default_splash') {
                return reply.status(400).send({ 
                    success: false,
                    message: 'Cannot delete default splash content.' 
                });
            }

            const result = await SplashContent.deleteOne({ contentId });
            
            if (result.deletedCount === 0) {
                return reply.status(404).send({ 
                    success: false,
                    message: 'Splash content not found.' 
                });
            }

            reply.status(200).send({
                success: true,
                message: 'Splash content deleted successfully.'
            });

        } catch (error) {
            console.error("Delete splash content error:", error);
            reply.status(500).send({ 
                success: false,
                message: 'Error deleting splash content.',
                error: process.env.NODE_ENV === 'development' ? error.message : undefined
            });
        }
    });
}

module.exports = splashRoutes;

