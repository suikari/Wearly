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

# NaverLogin 관련
-keep public class com.nhn.android.naverlogin.** {
  public protected *;
}
-keep public class com.navercorp.nid.** {
  public *;
}

# 코루틴 Continuation 유지
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation

# Retrofit 관련 유지
-keep interface * {
    @retrofit2.http.* <methods>;
}
-keep class retrofit2.Response { *; }
