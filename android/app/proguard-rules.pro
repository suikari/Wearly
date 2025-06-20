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

# Naver login SDK
-keep class com.navercorp.** { *; }
-dontwarn com.navercorp.**

# Kotlin 어노테이션 유지
-keepattributes *Annotation*
-keep class kotlin.Metadata { *; }

# Flutter 메서드 채널 보호
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**