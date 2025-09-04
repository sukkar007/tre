const path = require('path');
const fs = require('fs').promises;
const crypto = require('crypto');
const multer = require('multer');
const ffprobe = require('ffprobe');
const ffprobeStatic = require('ffprobe-static');

/**
 * مسارات رفع الملفات
 */
async function uploadRoutes(fastify, options) {

  // إعداد multer لرفع الملفات
  const storage = multer.diskStorage({
    destination: async (req, file, cb) => {
      const uploadDir = path.join(__dirname, '../uploads/audio');
      try {
        await fs.mkdir(uploadDir, { recursive: true });
        cb(null, uploadDir);
      } catch (error) {
        cb(error);
      }
    },
    filename: (req, file, cb) => {
      // إنشاء اسم ملف فريد
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
      const ext = path.extname(file.originalname);
      cb(null, `audio-${uniqueSuffix}${ext}`);
    }
  });

  const upload = multer({
    storage: storage,
    limits: {
      fileSize: 50 * 1024 * 1024, // 50MB حد أقصى
    },
    fileFilter: (req, file, cb) => {
      // التحقق من نوع الملف
      const allowedMimes = [
        'audio/mpeg',
        'audio/mp3',
        'audio/wav',
        'audio/ogg',
        'audio/aac',
        'audio/flac',
        'audio/m4a'
      ];
      
      if (allowedMimes.includes(file.mimetype)) {
        cb(null, true);
      } else {
        cb(new Error('نوع الملف غير مدعوم. يرجى رفع ملف صوتي صحيح.'));
      }
    }
  });

  // تسجيل multer كـ plugin
  await fastify.register(require('@fastify/multipart'), {
    limits: {
      fileSize: 50 * 1024 * 1024, // 50MB
    }
  });

  /**
   * رفع ملف صوتي
   * POST /api/upload/audio
   */
  fastify.post('/audio', {
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      const data = await request.file();
      
      if (!data) {
        return reply.status(400).send({
          success: false,
          error: 'لم يتم العثور على ملف'
        });
      }

      // التحقق من نوع الملف
      const allowedMimes = [
        'audio/mpeg',
        'audio/mp3',
        'audio/wav',
        'audio/ogg',
        'audio/aac',
        'audio/flac',
        'audio/m4a'
      ];

      if (!allowedMimes.includes(data.mimetype)) {
        return reply.status(400).send({
          success: false,
          error: 'نوع الملف غير مدعوم. يرجى رفع ملف صوتي صحيح.'
        });
      }

      // إنشاء مجلد الرفع إذا لم يكن موجوداً
      const uploadDir = path.join(__dirname, '../uploads/audio');
      await fs.mkdir(uploadDir, { recursive: true });

      // إنشاء اسم ملف فريد
      const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
      const ext = path.extname(data.filename);
      const filename = `audio-${uniqueSuffix}${ext}`;
      const filepath = path.join(uploadDir, filename);

      // حفظ الملف
      const buffer = await data.toBuffer();
      await fs.writeFile(filepath, buffer);

      // الحصول على معلومات الملف الصوتي
      let audioInfo;
      try {
        audioInfo = await ffprobe(filepath, { path: ffprobeStatic.path });
      } catch (error) {
        // إذا فشل ffprobe، استخدم معلومات أساسية
        fastify.log.warn('فشل في الحصول على معلومات الملف الصوتي:', error);
        audioInfo = {
          streams: [{
            duration: 0,
            bit_rate: 0
          }],
          format: {
            format_name: path.extname(data.filename).slice(1)
          }
        };
      }

      const audioStream = audioInfo.streams.find(stream => stream.codec_type === 'audio') || audioInfo.streams[0];
      const duration = Math.floor(parseFloat(audioStream.duration || 0));
      const bitrate = parseInt(audioStream.bit_rate || 0);
      const format = audioInfo.format.format_name || path.extname(data.filename).slice(1);

      // إنشاء URL للملف
      const fileUrl = `${process.env.BASE_URL || 'http://localhost:3000'}/uploads/audio/${filename}`;

      // حساب hash للملف للتحقق من التكرار
      const fileHash = crypto.createHash('md5').update(buffer).digest('hex');

      const result = {
        success: true,
        message: 'تم رفع الملف بنجاح',
        file: {
          originalName: data.filename,
          filename: filename,
          filepath: filepath,
          fileUrl: fileUrl,
          fileSize: buffer.length,
          mimetype: data.mimetype,
          duration: duration,
          bitrate: bitrate,
          format: format,
          hash: fileHash,
          uploadedAt: new Date().toISOString()
        }
      };

      return result;

    } catch (error) {
      fastify.log.error('خطأ في رفع الملف الصوتي:', error);
      
      // حذف الملف في حالة الخطأ
      if (error.filepath) {
        try {
          await fs.unlink(error.filepath);
        } catch (unlinkError) {
          fastify.log.error('خطأ في حذف الملف:', unlinkError);
        }
      }

      return reply.status(500).send({
        success: false,
        error: 'خطأ في رفع الملف',
        message: error.message
      });
    }
  });

  /**
   * رفع عدة ملفات صوتية
   * POST /api/upload/audio/multiple
   */
  fastify.post('/audio/multiple', {
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      const files = [];
      const uploadedFiles = [];
      const errors = [];

      // معالجة الملفات المتعددة
      for await (const part of request.parts()) {
        if (part.file) {
          files.push(part);
        }
      }

      if (files.length === 0) {
        return reply.status(400).send({
          success: false,
          error: 'لم يتم العثور على ملفات'
        });
      }

      // معالجة كل ملف
      for (const file of files) {
        try {
          // التحقق من نوع الملف
          const allowedMimes = [
            'audio/mpeg',
            'audio/mp3',
            'audio/wav',
            'audio/ogg',
            'audio/aac',
            'audio/flac',
            'audio/m4a'
          ];

          if (!allowedMimes.includes(file.mimetype)) {
            errors.push({
              filename: file.filename,
              error: 'نوع الملف غير مدعوم'
            });
            continue;
          }

          // إنشاء مجلد الرفع
          const uploadDir = path.join(__dirname, '../uploads/audio');
          await fs.mkdir(uploadDir, { recursive: true });

          // إنشاء اسم ملف فريد
          const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
          const ext = path.extname(file.filename);
          const filename = `audio-${uniqueSuffix}${ext}`;
          const filepath = path.join(uploadDir, filename);

          // حفظ الملف
          const buffer = await file.toBuffer();
          await fs.writeFile(filepath, buffer);

          // الحصول على معلومات الملف
          let audioInfo;
          try {
            audioInfo = await ffprobe(filepath, { path: ffprobeStatic.path });
          } catch (error) {
            audioInfo = {
              streams: [{ duration: 0, bit_rate: 0 }],
              format: { format_name: ext.slice(1) }
            };
          }

          const audioStream = audioInfo.streams.find(stream => stream.codec_type === 'audio') || audioInfo.streams[0];
          const duration = Math.floor(parseFloat(audioStream.duration || 0));
          const bitrate = parseInt(audioStream.bit_rate || 0);
          const format = audioInfo.format.format_name || ext.slice(1);

          const fileUrl = `${process.env.BASE_URL || 'http://localhost:3000'}/uploads/audio/${filename}`;
          const fileHash = crypto.createHash('md5').update(buffer).digest('hex');

          uploadedFiles.push({
            originalName: file.filename,
            filename: filename,
            filepath: filepath,
            fileUrl: fileUrl,
            fileSize: buffer.length,
            mimetype: file.mimetype,
            duration: duration,
            bitrate: bitrate,
            format: format,
            hash: fileHash,
            uploadedAt: new Date().toISOString()
          });

        } catch (error) {
          errors.push({
            filename: file.filename,
            error: error.message
          });
        }
      }

      return {
        success: true,
        message: `تم رفع ${uploadedFiles.length} ملف بنجاح`,
        uploadedFiles: uploadedFiles,
        errors: errors,
        summary: {
          total: files.length,
          successful: uploadedFiles.length,
          failed: errors.length
        }
      };

    } catch (error) {
      fastify.log.error('خطأ في رفع الملفات المتعددة:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في رفع الملفات',
        message: error.message
      });
    }
  });

  /**
   * حذف ملف مرفوع
   * DELETE /api/upload/audio/:filename
   */
  fastify.delete('/audio/:filename', {
    schema: {
      params: {
        type: 'object',
        required: ['filename'],
        properties: {
          filename: { type: 'string' }
        }
      }
    },
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      const { filename } = request.params;
      const filepath = path.join(__dirname, '../uploads/audio', filename);

      // التحقق من وجود الملف
      try {
        await fs.access(filepath);
      } catch (error) {
        return reply.status(404).send({
          success: false,
          error: 'الملف غير موجود'
        });
      }

      // حذف الملف
      await fs.unlink(filepath);

      return {
        success: true,
        message: 'تم حذف الملف بنجاح'
      };

    } catch (error) {
      fastify.log.error('خطأ في حذف الملف:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في حذف الملف',
        message: error.message
      });
    }
  });

  /**
   * الحصول على معلومات ملف
   * GET /api/upload/audio/:filename/info
   */
  fastify.get('/audio/:filename/info', {
    schema: {
      params: {
        type: 'object',
        required: ['filename'],
        properties: {
          filename: { type: 'string' }
        }
      }
    },
    preHandler: [fastify.authenticate]
  }, async (request, reply) => {
    try {
      const { filename } = request.params;
      const filepath = path.join(__dirname, '../uploads/audio', filename);

      // التحقق من وجود الملف
      try {
        await fs.access(filepath);
      } catch (error) {
        return reply.status(404).send({
          success: false,
          error: 'الملف غير موجود'
        });
      }

      // الحصول على معلومات الملف
      const stats = await fs.stat(filepath);
      
      let audioInfo;
      try {
        audioInfo = await ffprobe(filepath, { path: ffprobeStatic.path });
      } catch (error) {
        audioInfo = {
          streams: [{ duration: 0, bit_rate: 0 }],
          format: { format_name: path.extname(filename).slice(1) }
        };
      }

      const audioStream = audioInfo.streams.find(stream => stream.codec_type === 'audio') || audioInfo.streams[0];
      const duration = Math.floor(parseFloat(audioStream.duration || 0));
      const bitrate = parseInt(audioStream.bit_rate || 0);
      const format = audioInfo.format.format_name || path.extname(filename).slice(1);

      const fileUrl = `${process.env.BASE_URL || 'http://localhost:3000'}/uploads/audio/${filename}`;

      return {
        success: true,
        file: {
          filename: filename,
          filepath: filepath,
          fileUrl: fileUrl,
          fileSize: stats.size,
          duration: duration,
          bitrate: bitrate,
          format: format,
          createdAt: stats.birthtime.toISOString(),
          modifiedAt: stats.mtime.toISOString()
        }
      };

    } catch (error) {
      fastify.log.error('خطأ في الحصول على معلومات الملف:', error);
      return reply.status(500).send({
        success: false,
        error: 'خطأ في الحصول على معلومات الملف',
        message: error.message
      });
    }
  });
}

module.exports = uploadRoutes;

