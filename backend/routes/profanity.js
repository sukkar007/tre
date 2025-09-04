const { profanityFilter } = require('../services/profanityFilter');

/**
 * مسارات API لإدارة فلتر الكلمات السيئة
 */
async function profanityRoutes(fastify, options) {
  
  /**
   * فحص النص للكلمات السيئة
   * POST /api/profanity/check
   */
  fastify.post('/check', {
    schema: {
      body: {
        type: 'object',
        required: ['text'],
        properties: {
          text: { type: 'string', maxLength: 5000 },
          filterLevel: { type: 'integer', minimum: 1, maximum: 4 },
          returnFiltered: { type: 'boolean', default: true }
        }
      }
    }
  }, async (request, reply) => {
    try {
      const { text, filterLevel, returnFiltered = true } = request.body;
      
      // تحديث مستوى الفلترة إذا تم تمريره
      if (filterLevel) {
        profanityFilter.setFilterLevel(filterLevel);
      }
      
      // فحص النص
      const result = profanityFilter.checkText(text);
      
      // إعداد الاستجابة
      const response = {
        success: true,
        isClean: result.isClean,
        severity: result.severity,
        severityName: profanityFilter.getFilterLevelName(result.severity),
        foundWordsCount: result.foundWords.length,
        originalLength: text.length,
        filteredLength: result.filteredText.length
      };
      
      // إضافة النص المفلتر إذا طُلب
      if (returnFiltered) {
        response.filteredText = result.filteredText;
      }
      
      // إضافة الكلمات المكتشفة للمدراء فقط
      if (request.user && (request.user.role === 'admin' || request.user.role === 'moderator')) {
        response.foundWords = result.foundWords;
        response.originalText = result.originalText;
      }
      
      return response;
      
    } catch (error) {
      fastify.log.error('خطأ في فحص النص:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في فحص النص',
        message: error.message
      });
    }
  });

  /**
   * تنظيف النص من الكلمات السيئة
   * POST /api/profanity/clean
   */
  fastify.post('/clean', {
    schema: {
      body: {
        type: 'object',
        required: ['text'],
        properties: {
          text: { type: 'string', maxLength: 5000 },
          filterLevel: { type: 'integer', minimum: 1, maximum: 4 }
        }
      }
    }
  }, async (request, reply) => {
    try {
      const { text, filterLevel } = request.body;
      
      // تحديث مستوى الفلترة إذا تم تمريره
      if (filterLevel) {
        profanityFilter.setFilterLevel(filterLevel);
      }
      
      // تنظيف النص
      const cleanedText = profanityFilter.cleanText(text);
      const result = profanityFilter.checkText(text);
      
      return {
        success: true,
        originalText: text,
        cleanedText: cleanedText,
        wasFiltered: !result.isClean,
        changesCount: result.foundWords.length,
        severity: result.severity
      };
      
    } catch (error) {
      fastify.log.error('خطأ في تنظيف النص:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في تنظيف النص',
        message: error.message
      });
    }
  });

  /**
   * فحص سريع للنص (للاستخدام في الوقت الفعلي)
   * POST /api/profanity/quick-check
   */
  fastify.post('/quick-check', {
    schema: {
      body: {
        type: 'object',
        required: ['text'],
        properties: {
          text: { type: 'string', maxLength: 1000 }
        }
      }
    }
  }, async (request, reply) => {
    try {
      const { text } = request.body;
      
      // فحص سريع
      const isClean = profanityFilter.isTextClean(text);
      
      return {
        success: true,
        isClean: isClean,
        timestamp: new Date().toISOString()
      };
      
    } catch (error) {
      fastify.log.error('خطأ في الفحص السريع:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في الفحص السريع',
        message: error.message
      });
    }
  });

  /**
   * الحصول على إعدادات الفلتر
   * GET /api/profanity/settings
   */
  fastify.get('/settings', {
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      // التحقق من صلاحيات المدير
      if (!request.user || (request.user.role !== 'admin' && request.user.role !== 'moderator')) {
        return reply.status(403).send({
          success: false,
          error: 'غير مصرح لك بالوصول لهذه المعلومات'
        });
      }
      
      const stats = profanityFilter.getFilterStats();
      
      return {
        success: true,
        settings: {
          filterLevel: profanityFilter.filterLevel,
          filterLevelName: profanityFilter.getFilterLevelName(profanityFilter.filterLevel),
          replacementChar: profanityFilter.replacementChar,
          stats: stats
        }
      };
      
    } catch (error) {
      fastify.log.error('خطأ في الحصول على إعدادات الفلتر:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في الحصول على إعدادات الفلتر',
        message: error.message
      });
    }
  });

  /**
   * تحديث إعدادات الفلتر
   * PUT /api/profanity/settings
   */
  fastify.put('/settings', {
    schema: {
      body: {
        type: 'object',
        properties: {
          filterLevel: { type: 'integer', minimum: 1, maximum: 4 },
          replacementChar: { type: 'string', maxLength: 5 },
          customBadWords: {
            type: 'array',
            items: {
              type: 'object',
              properties: {
                word: { type: 'string' },
                severity: { type: 'integer', minimum: 1, maximum: 4 }
              }
            }
          },
          whitelist: {
            type: 'array',
            items: { type: 'string' }
          }
        }
      }
    },
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      // التحقق من صلاحيات المدير
      if (!request.user || request.user.role !== 'admin') {
        return reply.status(403).send({
          success: false,
          error: 'غير مصرح لك بتعديل إعدادات الفلتر'
        });
      }
      
      const settings = request.body;
      
      // تحديث الإعدادات
      profanityFilter.updateSettings(settings);
      
      // حفظ الإعدادات
      const settingsPath = './data/profanity-settings.json';
      profanityFilter.saveSettings(settingsPath);
      
      return {
        success: true,
        message: 'تم تحديث إعدادات الفلتر بنجاح',
        newSettings: {
          filterLevel: profanityFilter.filterLevel,
          filterLevelName: profanityFilter.getFilterLevelName(profanityFilter.filterLevel),
          replacementChar: profanityFilter.replacementChar
        }
      };
      
    } catch (error) {
      fastify.log.error('خطأ في تحديث إعدادات الفلتر:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في تحديث إعدادات الفلتر',
        message: error.message
      });
    }
  });

  /**
   * إضافة كلمة مخصصة للقائمة السوداء
   * POST /api/profanity/add-word
   */
  fastify.post('/add-word', {
    schema: {
      body: {
        type: 'object',
        required: ['word'],
        properties: {
          word: { type: 'string', minLength: 1, maxLength: 50 },
          severity: { type: 'integer', minimum: 1, maximum: 4, default: 2 }
        }
      }
    },
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      // التحقق من صلاحيات المدير
      if (!request.user || request.user.role !== 'admin') {
        return reply.status(403).send({
          success: false,
          error: 'غير مصرح لك بإضافة كلمات للفلتر'
        });
      }
      
      const { word, severity = 2 } = request.body;
      
      // إضافة الكلمة
      profanityFilter.addCustomBadWord(word, severity);
      
      // حفظ الإعدادات
      const settingsPath = './data/profanity-settings.json';
      profanityFilter.saveSettings(settingsPath);
      
      return {
        success: true,
        message: `تم إضافة الكلمة "${word}" للقائمة السوداء`,
        word: word,
        severity: severity,
        severityName: profanityFilter.getFilterLevelName(severity)
      };
      
    } catch (error) {
      fastify.log.error('خطأ في إضافة كلمة للفلتر:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في إضافة كلمة للفلتر',
        message: error.message
      });
    }
  });

  /**
   * إضافة كلمة للقائمة البيضاء
   * POST /api/profanity/whitelist
   */
  fastify.post('/whitelist', {
    schema: {
      body: {
        type: 'object',
        required: ['word'],
        properties: {
          word: { type: 'string', minLength: 1, maxLength: 50 }
        }
      }
    },
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      // التحقق من صلاحيات المدير
      if (!request.user || request.user.role !== 'admin') {
        return reply.status(403).send({
          success: false,
          error: 'غير مصرح لك بتعديل القائمة البيضاء'
        });
      }
      
      const { word } = request.body;
      
      // إضافة الكلمة للقائمة البيضاء
      profanityFilter.addToWhitelist(word);
      
      // حفظ الإعدادات
      const settingsPath = './data/profanity-settings.json';
      profanityFilter.saveSettings(settingsPath);
      
      return {
        success: true,
        message: `تم إضافة الكلمة "${word}" للقائمة البيضاء`,
        word: word
      };
      
    } catch (error) {
      fastify.log.error('خطأ في إضافة كلمة للقائمة البيضاء:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في إضافة كلمة للقائمة البيضاء',
        message: error.message
      });
    }
  });

  /**
   * الحصول على إحصائيات الفلتر
   * GET /api/profanity/stats
   */
  fastify.get('/stats', {
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      // التحقق من صلاحيات المدير
      if (!request.user || (request.user.role !== 'admin' && request.user.role !== 'moderator')) {
        return reply.status(403).send({
          success: false,
          error: 'غير مصرح لك بالوصول لهذه الإحصائيات'
        });
      }
      
      const stats = profanityFilter.getFilterStats();
      
      return {
        success: true,
        stats: stats,
        timestamp: new Date().toISOString()
      };
      
    } catch (error) {
      fastify.log.error('خطأ في الحصول على إحصائيات الفلتر:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في الحصول على إحصائيات الفلتر',
        message: error.message
      });
    }
  });

  /**
   * اختبار الفلتر مع نصوص متعددة
   * POST /api/profanity/batch-check
   */
  fastify.post('/batch-check', {
    schema: {
      body: {
        type: 'object',
        required: ['texts'],
        properties: {
          texts: {
            type: 'array',
            maxItems: 100,
            items: { type: 'string', maxLength: 1000 }
          },
          filterLevel: { type: 'integer', minimum: 1, maximum: 4 }
        }
      }
    },
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      // التحقق من صلاحيات المدير
      if (!request.user || (request.user.role !== 'admin' && request.user.role !== 'moderator')) {
        return reply.status(403).send({
          success: false,
          error: 'غير مصرح لك باستخدام الفحص المجمع'
        });
      }
      
      const { texts, filterLevel } = request.body;
      
      // تحديث مستوى الفلترة إذا تم تمريره
      if (filterLevel) {
        profanityFilter.setFilterLevel(filterLevel);
      }
      
      // فحص جميع النصوص
      const results = texts.map((text, index) => {
        const result = profanityFilter.checkText(text);
        return {
          index: index,
          originalText: text,
          isClean: result.isClean,
          severity: result.severity,
          foundWordsCount: result.foundWords.length,
          filteredText: result.filteredText
        };
      });
      
      // إحصائيات عامة
      const cleanTexts = results.filter(r => r.isClean).length;
      const dirtyTexts = results.filter(r => !r.isClean).length;
      const totalWords = results.reduce((sum, r) => sum + r.foundWordsCount, 0);
      
      return {
        success: true,
        totalTexts: texts.length,
        cleanTexts: cleanTexts,
        dirtyTexts: dirtyTexts,
        totalBadWords: totalWords,
        results: results
      };
      
    } catch (error) {
      fastify.log.error('خطأ في الفحص المجمع:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في الفحص المجمع',
        message: error.message
      });
    }
  });
}

module.exports = profanityRoutes;

