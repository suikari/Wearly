# Kakao SDK
-keep class com.kakao.** { *; }
-dontwarn com.kakao.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**
-keep class kotlinx.** { *; }
-dontwarn kotlinx.**

# Flutter (MethodChannel, PlatformView 등)
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**
