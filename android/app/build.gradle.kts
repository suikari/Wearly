plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.w2wproject"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.w2wproject"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders += mapOf(
            "NAVER_CLIENT_ID" to "G0sonEyPthLnRvkvNR7j",
            "NAVER_CLIENT_SECRET" to "Xdef_o0yOx",
            "NAVER_CLIENT_NAME" to "wearly",
            "kakao_app_key" to "102bf4d0a6bfeeab56fd2d28f7573cc1",
            "kakao_scheme" to "kakao102bf4d0a6"
        )
    }

    dependencies {
        implementation("com.squareup.okhttp3:okhttp:4.12.0")
        implementation("androidx.work:work-runtime:2.8.1")
        implementation("com.kakao.sdk:v2-user:2.21.4")
        implementation("com.google.guava:guava:31.1-android")
        implementation("com.google.android.gms:play-services-location:21.0.1")
        // 예: kotlin stdlib
        implementation(kotlin("stdlib"))

        // 기타 의존성들 ...
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
