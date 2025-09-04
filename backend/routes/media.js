const { mediaService } = require('../services/mediaService');
const MediaContent = require('../models/MediaContent');

/**
 * مسارات API لإدارة الوسائط في الغرف الصوتية
 */
async function mediaRoutes(fastify, options) {

  /**
   * الحصول على المحتوى النشط في الغرفة
   * GET /api/media/room/:roomId/active
   */
  fastify.get('/room/:roomId/active', {
    schema: {
      params: {
        type: 'object',
        required: ['roomId'],
        properties: {
          roomId: { type: 'string' }
        }
      }
    },
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      const { roomId } = request.params;
      
      const activeContent = await mediaService.getActiveContent(roomId);
      
      return {
        success: true,
        activeContent: activeContent,
        timestamp: new Date().toISOString()
      };
      
    } catch (error) {
      fastify.log.error('خطأ في الحصول على المحتوى النشط:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في الحصول على المحتوى النشط',
        message: error.message
      });
    }
  });

  /**
   * الحصول على قائمة المحتوى في الغرفة
   * GET /api/media/room/:roomId/content
   */
  fastify.get('/room/:roomId/content', {
    schema: {
      params: {
        type: 'object',
        required: ['roomId'],
        properties: {
          roomId: { type: 'string' }
        }
      },
      querystring: {
        type: 'object',
        properties: {
          page: { type: 'integer', minimum: 1, default: 1 },
          limit: { type: 'integer', minimum: 1, maximum: 50, default: 20 },
          type: { type: 'string', enum: ['youtube', 'audio_file', 'playlist'] }
        }
      }
    },
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      const { roomId } = request.params;
      const { page = 1, limit = 20, type } = request.query;
      
      let filter = { roomId };
      if (type) {
        filter.type = type;
      }
      
      const result = await mediaService.getRoomContent(roomId, page, limit);
      
      return {
        success: true,
        ...result,
        timestamp: new Date().toISOString()
      };
      
    } catch (error) {
      fastify.log.error('خطأ في الحصول على محتوى الغرفة:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في الحصول على محتوى الغرفة',
        message: error.message
      });
    }
  });

  /**
   * إضافة فيديو YouTube
   * POST /api/media/room/:roomId/youtube
   */
  fastify.post('/room/:roomId/youtube', {
    schema: {
      params: {
        type: 'object',
        required: ['roomId'],
        properties: {
          roomId: { type: 'string' }
        }
      },
      body: {
        type: 'object',
        required: ['videoId', 'title'],
        properties: {
          videoId: { type: 'string', minLength: 11, maxLength: 11 },
          title: { type: 'string', maxLength: 200 },
          description: { type: 'string', maxLength: 1000 },
          channelName: { type: 'string', maxLength: 100 },
          duration: { type: 'integer', minimum: 1 },
          thumbnailUrl: { type: 'string', format: 'uri' },
          viewCount: { type: 'integer', minimum: 0 },
          publishedAt: { type: 'string', format: 'date-time' }
        }
      }
    },
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      const { roomId } = request.params;
      const videoInfo = request.body;
      const userId = request.user.id;
      
      // التحقق من وجود الفيديو مسبقاً
      const existingContent = await MediaContent.findOne({
        roomId,
        'youtubeData.videoId': videoInfo.videoId
      });
      
      if (existingContent) {
        return reply.status(409).send({
          success: false,
          error: 'هذا الفيديو موجود بالفعل في الغرفة',
          existingContent: await mediaService.getContentInfo(existingContent)
        });
      }
      
      const result = await mediaService.addYouTubeContent(
        roomId,
        videoInfo.videoId,
        userId,
        videoInfo
      );
      
      return result;
      
    } catch (error) {
      fastify.log.error('خطأ في إضافة فيديو YouTube:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في إضافة فيديو YouTube',
        message: error.message
      });
    }
  });

  /**
   * إضافة ملف صوتي
   * POST /api/media/room/:roomId/audio
   */
  fastify.post('/room/:roomId/audio', {
    schema: {
      params: {
        type: 'object',
        required: ['roomId'],
        properties: {
          roomId: { type: 'string' }
        }
      },
      body: {
        type: 'object',
        required: ['fileName', 'fileSize', 'duration'],
        properties: {
          fileName: { type: 'string', maxLength: 255 },
          fileSize: { type: 'integer', minimum: 1 },
          duration: { type: 'integer', minimum: 1 },
          format: { type: 'string', maxLength: 10 },
          bitrate: { type: 'integer', minimum: 32 }
        }
      }
    },
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      const { roomId } = request.params;
      const fileInfo = request.body;
      const userId = request.user.id;
      
      const result = await mediaService.addAudioFile(roomId, fileInfo, userId);
      
      return result;
      
    } catch (error) {
      fastify.log.error('خطأ في إضافة الملف الصوتي:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في إضافة الملف الصوتي',
        message: error.message
      });
    }
  });

  /**
   * بدء تشغيل المحتوى
   * POST /api/media/room/:roomId/play
   */
  fastify.post('/room/:roomId/play', {
    schema: {
      params: {
        type: 'object',
        required: ['roomId'],
        properties: {
          roomId: { type: 'string' }
        }
      },
      body: {
        type: 'object',
        required: ['contentId'],
        properties: {
          contentId: { type: 'string' },
          startPosition: { type: 'number', minimum: 0, default: 0 }
        }
      }
    },
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      const { roomId } = request.params;
      const { contentId, startPosition = 0 } = request.body;
      const userId = request.user.id;
      
      const result = await mediaService.startContent(
        roomId,
        contentId,
        userId,
        startPosition
      );
      
      return result;
      
    } catch (error) {
      fastify.log.error('خطأ في بدء تشغيل المحتوى:', error);
      return reply.status(400).send({
        success: false,
        error: 'خطأ في بدء تشغيل المحتوى',
        message: error.message
      });
    }
  });

  /**
   * إيقاف تشغيل المحتوى
   * POST /api/media/room/:roomId/pause
   */
  fastify.post('/room/:roomId/pause', {
    schema: {
      params: {
        type: 'object',
        required: ['roomId'],
        properties: {
          roomId: { type: 'string' }
        }
      },
      body: {
        type: 'object',
        required: ['contentId'],
        properties: {
          contentId: { type: 'string' }
        }
      }
    },
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      const { roomId } = request.params;
      const { contentId } = request.body;
      const userId = request.user.id;
      
      const result = await mediaService.pauseContent(roomId, contentId, userId);
      
      return result;
      
    } catch (error) {
      fastify.log.error('خطأ في إيقاف المحتوى:', error);
      return reply.status(400).send({
        success: false,
        error: 'خطأ في إيقاف المحتوى',
        message: error.message
      });
    }
  });

  /**
   * إيقاف جميع المحتوى
   * POST /api/media/room/:roomId/stop
   */
  fastify.post('/room/:roomId/stop', {
    schema: {
      params: {
        type: 'object',
        required: ['roomId'],
        properties: {
          roomId: { type: 'string' }
        }
      }
    },
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      const { roomId } = request.params;
      
      const result = await mediaService.stopAllContent(roomId);
      
      return {
        success: true,
        message: 'تم إيقاف جميع المحتوى'
      };
      
    } catch (error) {
      fastify.log.error('خطأ في إيقاف جميع المحتوى:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في إيقاف جميع المحتوى',
        message: error.message
      });
    }
  });

  /**
   * تغيير موقع التشغيل
   * POST /api/media/room/:roomId/seek
   */
  fastify.post('/room/:roomId/seek', {
    schema: {
      params: {
        type: 'object',
        required: ['roomId'],
        properties: {
          roomId: { type: 'string' }
        }
      },
      body: {
        type: 'object',
        required: ['contentId', 'position'],
        properties: {
          contentId: { type: 'string' },
          position: { type: 'number', minimum: 0 }
        }
      }
    },
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      const { roomId } = request.params;
      const { contentId, position } = request.body;
      const userId = request.user.id;
      
      const result = await mediaService.seekContent(
        roomId,
        contentId,
        userId,
        position
      );
      
      return result;
      
    } catch (error) {
      fastify.log.error('خطأ في تغيير موقع التشغيل:', error);
      return reply.status(400).send({
        success: false,
        error: 'خطأ في تغيير موقع التشغيل',
        message: error.message
      });
    }
  });

  /**
   * تغيير مستوى الصوت
   * POST /api/media/room/:roomId/volume
   */
  fastify.post('/room/:roomId/volume', {
    schema: {
      params: {
        type: 'object',
        required: ['roomId'],
        properties: {
          roomId: { type: 'string' }
        }
      },
      body: {
        type: 'object',
        required: ['contentId', 'volume'],
        properties: {
          contentId: { type: 'string' },
          volume: { type: 'integer', minimum: 0, maximum: 100 }
        }
      }
    },
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      const { roomId } = request.params;
      const { contentId, volume } = request.body;
      const userId = request.user.id;
      
      const result = await mediaService.changeVolume(
        roomId,
        contentId,
        userId,
        volume
      );
      
      return result;
      
    } catch (error) {
      fastify.log.error('خطأ في تغيير مستوى الصوت:', error);
      return reply.status(400).send({
        success: false,
        error: 'خطأ في تغيير مستوى الصوت',
        message: error.message
      });
    }
  });

  /**
   * حذف محتوى
   * DELETE /api/media/room/:roomId/content/:contentId
   */
  fastify.delete('/room/:roomId/content/:contentId', {
    schema: {
      params: {
        type: 'object',
        required: ['roomId', 'contentId'],
        properties: {
          roomId: { type: 'string' },
          contentId: { type: 'string' }
        }
      }
    },
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      const { roomId, contentId } = request.params;
      const userId = request.user.id;
      
      const result = await mediaService.deleteContent(roomId, contentId, userId);
      
      return result;
      
    } catch (error) {
      fastify.log.error('خطأ في حذف المحتوى:', error);
      return reply.status(400).send({
        success: false,
        error: 'خطأ في حذف المحتوى',
        message: error.message
      });
    }
  });

  /**
   * إنشاء قائمة تشغيل
   * POST /api/media/room/:roomId/playlist
   */
  fastify.post('/room/:roomId/playlist', {
    schema: {
      params: {
        type: 'object',
        required: ['roomId'],
        properties: {
          roomId: { type: 'string' }
        }
      },
      body: {
        type: 'object',
        required: ['title'],
        properties: {
          title: { type: 'string', maxLength: 200 },
          description: { type: 'string', maxLength: 1000 },
          items: {
            type: 'array',
            maxItems: 100,
            items: {
              type: 'object',
              required: ['contentId'],
              properties: {
                contentId: { type: 'string' },
                duration: { type: 'integer', minimum: 1 }
              }
            }
          }
        }
      }
    },
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      const { roomId } = request.params;
      const { title, description, items = [] } = request.body;
      const userId = request.user.id;
      
      const playlist = await MediaContent.createPlaylist(
        roomId,
        title,
        userId,
        items
      );
      
      return {
        success: true,
        message: 'تم إنشاء قائمة التشغيل',
        playlist: await mediaService.getContentInfo(playlist)
      };
      
    } catch (error) {
      fastify.log.error('خطأ في إنشاء قائمة التشغيل:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في إنشاء قائمة التشغيل',
        message: error.message
      });
    }
  });

  /**
   * تقييم المحتوى
   * POST /api/media/room/:roomId/content/:contentId/rate
   */
  fastify.post('/room/:roomId/content/:contentId/rate', {
    schema: {
      params: {
        type: 'object',
        required: ['roomId', 'contentId'],
        properties: {
          roomId: { type: 'string' },
          contentId: { type: 'string' }
        }
      },
      body: {
        type: 'object',
        required: ['rating'],
        properties: {
          rating: { type: 'integer', minimum: 1, maximum: 5 }
        }
      }
    },
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      const { roomId, contentId } = request.params;
      const { rating } = request.body;
      
      const content = await MediaContent.findOne({ contentId, roomId });
      if (!content) {
        return reply.status(404).send({
          success: false,
          error: 'المحتوى غير موجود'
        });
      }
      
      await content.addRating(rating);
      
      return {
        success: true,
        message: 'تم إضافة التقييم',
        averageRating: content.stats.averageRating,
        ratingCount: content.stats.ratingCount
      };
      
    } catch (error) {
      fastify.log.error('خطأ في تقييم المحتوى:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في تقييم المحتوى',
        message: error.message
      });
    }
  });

  /**
   * الحصول على إحصائيات الوسائط
   * GET /api/media/room/:roomId/stats
   */
  fastify.get('/room/:roomId/stats', {
    schema: {
      params: {
        type: 'object',
        required: ['roomId'],
        properties: {
          roomId: { type: 'string' }
        }
      }
    },
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      const { roomId } = request.params;
      
      const stats = await MediaContent.aggregate([
        { $match: { roomId: new mongoose.Types.ObjectId(roomId) } },
        {
          $group: {
            _id: null,
            totalContent: { $sum: 1 },
            totalPlays: { $sum: '$stats.totalPlays' },
            totalListeners: { $sum: '$stats.totalListeners' },
            averageRating: { $avg: '$stats.averageRating' },
            youtubeCount: {
              $sum: { $cond: [{ $eq: ['$type', 'youtube'] }, 1, 0] }
            },
            audioCount: {
              $sum: { $cond: [{ $eq: ['$type', 'audio_file'] }, 1, 0] }
            },
            playlistCount: {
              $sum: { $cond: [{ $eq: ['$type', 'playlist'] }, 1, 0] }
            }
          }
        }
      ]);
      
      return {
        success: true,
        stats: stats[0] || {
          totalContent: 0,
          totalPlays: 0,
          totalListeners: 0,
          averageRating: 0,
          youtubeCount: 0,
          audioCount: 0,
          playlistCount: 0
        },
        timestamp: new Date().toISOString()
      };
      
    } catch (error) {
      fastify.log.error('خطأ في الحصول على إحصائيات الوسائط:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في الحصول على إحصائيات الوسائط',
        message: error.message
      });
    }
  });
}

module.exports = mediaRoutes;

