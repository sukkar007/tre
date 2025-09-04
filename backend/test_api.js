const axios = require('axios');

const BASE_URL = 'http://localhost:3000';

// ألوان للطباعة
const colors = {
  green: '\x1b[32m',
  red: '\x1b[31m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  reset: '\x1b[0m',
  bold: '\x1b[1m'
};

function log(color, message) {
  console.log(`${color}${message}${colors.reset}`);
}

async function testAPI() {
  log(colors.bold + colors.blue, '🧪 بدء اختبار API endpoints...\n');

  // اختبار 1: الصفحة الرئيسية
  try {
    log(colors.yellow, '📍 اختبار 1: الصفحة الرئيسية');
    const response = await axios.get(`${BASE_URL}/`);
    log(colors.green, '✅ نجح: ' + JSON.stringify(response.data));
  } catch (error) {
    log(colors.red, '❌ فشل: ' + error.message);
  }

  console.log('');

  // اختبار 2: محتوى Splash
  try {
    log(colors.yellow, '📍 اختبار 2: محتوى Splash');
    const response = await axios.get(`${BASE_URL}/api/splash/content?platform=android`);
    log(colors.green, '✅ نجح: تم استلام محتوى Splash');
    log(colors.blue, `   العنوان: ${response.data.content.title}`);
    log(colors.blue, `   الوصف: ${response.data.content.description}`);
  } catch (error) {
    log(colors.red, '❌ فشل: ' + error.message);
  }

  console.log('');

  // اختبار 3: تسجيل نقرة إعلان
  try {
    log(colors.yellow, '📍 اختبار 3: تسجيل نقرة إعلان');
    const response = await axios.post(`${BASE_URL}/api/splash/ad-click`, {
      contentId: 'default_splash',
      adId: 'test_ad_123'
    });
    log(colors.green, '✅ نجح: ' + JSON.stringify(response.data));
  } catch (error) {
    log(colors.red, '❌ فشل: ' + error.message);
  }

  console.log('');

  // اختبار 4: تسجيل دخول وهمي (بدون Firebase)
  try {
    log(colors.yellow, '📍 اختبار 4: تسجيل دخول وهمي');
    const response = await axios.post(`${BASE_URL}/api/auth/login`, {
      idToken: 'fake_token_for_testing',
      deviceId: 'test_device_123'
    });
    log(colors.green, '✅ نجح: ' + JSON.stringify(response.data));
  } catch (error) {
    if (error.response) {
      log(colors.yellow, '⚠️ متوقع: ' + error.response.data.message);
    } else {
      log(colors.red, '❌ فشل: ' + error.message);
    }
  }

  console.log('');

  // اختبار 5: إنشاء محتوى Splash جديد
  try {
    log(colors.yellow, '📍 اختبار 5: إنشاء محتوى Splash جديد');
    const response = await axios.post(`${BASE_URL}/api/splash/content`, {
      contentId: 'test_splash_' + Date.now(),
      title: 'اختبار محتوى جديد',
      subtitle: 'هذا محتوى تجريبي',
      description: 'تم إنشاؤه من خلال اختبار API',
      primaryColor: '#ff6b6b',
      secondaryColor: '#4ecdc4',
      textColor: '#ffffff',
      backgroundColor: '#2c3e50',
      displayDuration: 4000,
      showProgressBar: true,
      animationType: 'slide'
    });
    log(colors.green, '✅ نجح: تم إنشاء محتوى Splash جديد');
    log(colors.blue, `   معرف المحتوى: ${response.data.content.contentId}`);
  } catch (error) {
    log(colors.red, '❌ فشل: ' + error.message);
  }

  console.log('');

  // اختبار 6: الحصول على قائمة المحتويات (للإدارة)
  try {
    log(colors.yellow, '📍 اختبار 6: قائمة محتويات Splash');
    const response = await axios.get(`${BASE_URL}/api/splash/admin/contents?page=1&limit=5`);
    log(colors.green, '✅ نجح: تم استلام قائمة المحتويات');
    log(colors.blue, `   عدد المحتويات: ${response.data.contents.length}`);
    log(colors.blue, `   إجمالي المحتويات: ${response.data.pagination.total}`);
  } catch (error) {
    log(colors.red, '❌ فشل: ' + error.message);
  }

  console.log('');
  log(colors.bold + colors.green, '🎉 انتهى اختبار API endpoints!');
}

// تشغيل الاختبارات
testAPI().catch(error => {
  log(colors.red, '💥 خطأ عام في الاختبار: ' + error.message);
  process.exit(1);
});

