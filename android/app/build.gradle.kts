import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val localProperties = Properties().apply {
    load(FileInputStream(File(rootDir, "local.properties")))
}

val kakaoKey = localProperties["kakao_app_key"] as String
val kakaoScheme = localProperties["kakao_scheme"] as String
val naverClientId = localProperties["NAVER_CLIENT_ID"] as String
val naverClientSecret = localProperties["NAVER_CLIENT_SECRET"] as String
val naverClientName = localProperties["NAVER_CLIENT_NAME"] as String

android {
    namespace = "com.example.w2wproject"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true // ✅ 이 줄 추가
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

//    signingConfigs {
//        create("release") {
//            storeFile = file(localProperties["storeFile"] as String)
//            storePassword = localProperties["storePassword"] as String
//            keyAlias = localProperties["keyAlias"] as String
//            keyPassword = localProperties["keyPassword"] as String
//        }
//    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.w2wproject"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 23
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        manifestPlaceholders["kakao_app_key"] = kakaoKey
        manifestPlaceholders["kakao_scheme"] = kakaoScheme
        manifestPlaceholders["NAVER_CLIENT_ID"] = naverClientId
        manifestPlaceholders["NAVER_CLIENT_SECRET"] = naverClientSecret
        manifestPlaceholders["NAVER_CLIENT_NAME"] = naverClientName
    }

    dependencies {
        implementation("com.squareup.okhttp3:okhttp:4.12.0")
        implementation("androidx.work:work-runtime:2.8.1")
        implementation("com.kakao.sdk:v2-user:2.21.4")
        implementation("com.navercorp.nid:oauth:5.10.0")
        implementation("com.google.guava:guava:31.1-android")
        implementation("com.google.android.gms:play-services-location:21.0.1")
        // 예: kotlin stdlib
        implementation(kotlin("stdlib"))
        coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

        // 기타 의존성들 ...
    }

    buildTypes {
//        getByName("release") {
//            signingConfig = signingConfigs.getByName("release")
//            isMinifyEnabled = true
//            isShrinkResources = true
//            proguardFiles(
//                getDefaultProguardFile("proguard-android-optimize.txt"),
//                "proguard-rules.pro"
//            )
//        }
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}
