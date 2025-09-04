#!/bin/bash

# 🚀 سكريبت بناء النسخة التجريبية - HUS App Demo
# يقوم ببناء APK تجريبي بدون الحاجة لإعدادات Firebase أو ZegoCloud

echo "🎯 بدء بناء النسخة التجريبية لتطبيق HUS..."
echo "=================================================="

# التحقق من وجود Flutter
if ! command -v flutter &> /dev/null; then
    echo "❌ خطأ: Flutter غير مثبت أو غير موجود في PATH"
    echo "يرجى تثبيت Flutter أولاً من: https://flutter.dev/docs/get-started/install"
    exit 1
fi

# التحقق من إصدار Flutter
echo "📋 فحص إصدار Flutter..."
flutter --version

# الانتقال لمجلد المشروع
cd frontend || {
    echo "❌ خطأ: لا يمكن العثور على مجلد frontend"
    exit 1
}

echo ""
echo "🔧 تحضير النسخة التجريبية..."

# نسخ إعدادات النسخة التجريبية
if [ -f "pubspec_demo.yaml" ]; then
    cp pubspec_demo.yaml pubspec.yaml
    echo "✅ تم تحديث pubspec.yaml للنسخة التجريبية"
else
    echo "⚠️  تحذير: ملف pubspec_demo.yaml غير موجود، سيتم استخدام الإعدادات الحالية"
fi

echo ""
echo "📦 تثبيت التبعيات..."

# تنظيف المشروع
flutter clean

# تثبيت التبعيات
flutter pub get

if [ $? -ne 0 ]; then
    echo "❌ خطأ في تثبيت التبعيات"
    echo "يرجى التحقق من ملف pubspec.yaml والاتصال بالإنترنت"
    exit 1
fi

echo ""
echo "🔍 فحص المشروع..."

# فحص المشروع للأخطاء
flutter analyze --no-fatal-infos

echo ""
echo "🏗️  بناء APK التجريبي..."

# بناء APK للنسخة التجريبية
flutter build apk --debug --target=lib/main.dart

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 تم بناء APK التجريبي بنجاح!"
    echo "=================================================="
    echo "📱 مسار الملف:"
    echo "   build/app/outputs/flutter-apk/app-debug.apk"
    echo ""
    echo "📊 معلومات الملف:"
    if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
        ls -lh build/app/outputs/flutter-apk/app-debug.apk
        echo ""
        echo "🔧 لتثبيت APK على الجهاز:"
        echo "   adb install build/app/outputs/flutter-apk/app-debug.apk"
        echo ""
        echo "📱 أو استخدم:"
        echo "   flutter install"
        echo ""
        echo "🎯 ميزات النسخة التجريبية:"
        echo "   ✅ تسجيل دخول فوري"
        echo "   ✅ 4 غرف صوتية وهمية"
        echo "   ✅ 5 مستخدمين تجريبيين"
        echo "   ✅ دردشة ووسائط وهمية"
        echo "   ✅ جميع الواجهات تعمل"
        echo ""
        echo "⚠️  ملاحظة: البيانات وهمية ولا تحتاج اتصال إنترنت"
    fi
else
    echo ""
    echo "❌ فشل في بناء APK"
    echo "يرجى التحقق من الأخطاء أعلاه وإعادة المحاولة"
    exit 1
fi

echo ""
echo "🚀 انتهى بناء النسخة التجريبية!"

