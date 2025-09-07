# مشروع HUS - الغرف الصوتية

هذا المشروع هو تطبيق Flutter للغرف الصوتية.

## المتطلبات

*   [Flutter SDK](https://flutter.dev/docs/get-started/install) (الإصدار الموصى به: 3.16.0)
*   [Android Studio](https://developer.android.com/studio) أو [VS Code](https://code.visualstudio.com/) مع ملحقات Flutter و Dart.
*   حساب [ZegoCloud](https://www.zegocloud.com/) للحصول على App ID و App Sign.

## الإعداد

1.  **استنساخ المستودع:**

    ```bash
    git clone https://github.com/sukkar007/tre.git
    cd tre/frontend
    ```

2.  **الحصول على التبعيات:**

    ```bash
    flutter pub get
    ```

3.  **تحديث معلومات ZegoCloud:**

    افتح الملف `lib/src/utils/app_constants.dart` وقم بتحديث `zegoAppID` و `zegoAppSign` بالمعلومات الخاصة بك من حساب ZegoCloud.

    ```dart
    class AppConstants {
      static const int zegoAppID = 595216571; // استبدل بمعرف التطبيق الخاص بك
      static const String zegoAppSign = "5e02666b0f2567c3cd7359dd526a898ae52ebd1a8b1db6b659aa3242084b5c37"; // استبدل بتوقيع التطبيق الخاص بك
      // ...
    }
    ```

4.  **تشغيل التطبيق (الوضع التجريبي):**

    للتشغيل في الوضع التجريبي (مع البيانات الوهمية والغرف غير المتصلة بـ ZegoCloud)، تأكد من أن `main.dart` يستخدم `HUSAppDemo`:

    ```dart
    void main() async {
      // ...
      runApp(const HUSAppDemo());
    }
    ```

    ثم قم بتشغيل التطبيق:

    ```bash
    flutter run
    ```

5.  **تشغيل التطبيق (مع ZegoCloud):**

    لتفعيل ميزات ZegoCloud، قم بتعديل `main.dart` لاستخدام `HUSApp` بدلاً من `HUSAppDemo`:

    ```dart
    void main() async {
      // ...
      runApp(const HUSApp());
    }
    ```

    **ملاحظة:** ستحتاج إلى إلغاء التعليق عن حزم ZegoCloud في `pubspec.yaml` إذا لم تكن كذلك:

    ```yaml
    dependencies:
      # ...
      zego_uikit_prebuilt_live_audio_room: ^3.16.4
      zego_uikit: ^2.28.26
      zego_express_engine: ^3.22.0
      # ...
    ```

    ثم قم بتشغيل التطبيق:

    ```bash
    flutter run
    ```

## استكشاف الأخطاء وإصلاحها

*   **مشاكل التبعيات:** إذا واجهت أخطاء في التبعيات، حاول تشغيل `flutter clean` ثم `flutter pub get`.
*   **مشاكل البناء:** تأكد من أن لديك أحدث إصدار من Flutter SDK وأن جميع التبعيات متوافقة.

أتمنى أن يساعدك هذا في تشغيل التطبيق وتجربة ميزاته. إذا واجهت أي مشاكل أخرى، فلا تتردد في السؤال.

