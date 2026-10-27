import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Đọc thông tin ký bản release từ android/key.properties.
// File này KHÔNG được commit lên git (đã thêm vào .gitignore).
//
// Nếu file không tồn tại (ví dụ người mới clone repo, hoặc CI chưa cấu hình bí mật),
// thì build release sẽ rơi về dùng debug key — và build đó KHÔNG submit được lên
// Google Play. Vì vậy ta in ra cảnh báo thay vì im lặng.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = keystorePropertiesFile.exists()
if (hasReleaseKeystore) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
} else {
    logger.warn(
        "=====================================================================\n" +
        "  KHONG TIM THAY android/key.properties\n" +
        "  Build release se dung DEBUG KEY -> KHONG the submit len Google Play.\n" +
        "  Xem docs/RELEASE.md cach tao khoa ky.\n" +
        "====================================================================="
    )
}

android {
    namespace = "com.wakeup.app"
    compileSdk = flutter.compileSdkVersion

    // NDK 28.2 là phiên bản mà các plugin sau yêu cầu:
    // app_links, audio_session, firebase_core, firebase_crashlytics,
    // flutter_secure_storage, home_widget, jni, just_audio, local_auth_android,
    // mixpanel_flutter, permission_handler_android, purchases_flutter,
    // shared_preferences_android, url_launcher_android.
    //
    // NDK tương thích ngược nên nâng lên bản cao hơn là an toàn. Nếu để 25.1
    // (như cấu hình cũ) thì build sẽ dừng với lỗi "plugin requires NDK 28.2".
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.wakeup.app"

        // PRD yêu cầu hỗ trợ Android 8.0 trở lên (API 26).
        minSdk = 26

        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Đa ngôn ngữ: các thư viện (flutter_localizations / play-services) sẽ
        // không bị R8 loại bỏ nhầm.
        resourceConfigurations += listOf("vi", "en")
    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                storeFile = file(keystoreProperties.getProperty("storeFile"))
                storePassword = keystoreProperties.getProperty("storePassword")
                keyAlias = keystoreProperties.getProperty("keyAlias")
                keyPassword = keystoreProperties.getProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                // Chỉ để cho `flutter run --release` chạy được khi thiếu khoá.
                // Build này KHÔNG submit được lên store.
                signingConfigs.getByName("debug")
            }

            // Bật R8: thu nhỏ + làm rối + bỏ code thừa.
            //
            // RỦI RO CẦN BIẾT: `AlarmService.resolveSoundUri()` tìm file nhạc chuông
            // bằng `resources.getIdentifier(name, "raw", ...)` — đây là tra cứu theo
            // CHUỖI, R8 không thể thấy nên có thể xoá các file trong res/raw.
            // Khối `-keepclassmembers class **.R$raw` trong proguard-rules.pro
            // là câu trả lời cho việc đó. KHÔNG ĐƯỢC XOÁ KHỐI ĐÓ.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }

        debug {
            // Giữ nguyên: bản debug cần tên class đọc được để debug/logcat hữu ích.
            isMinifyEnabled = false
        }
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}