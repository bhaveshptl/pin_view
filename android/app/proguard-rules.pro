#Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }
-keep class android.content.pm.**  { *; }
-dontwarn com.google.common.**
-dontwarn com.google.errorprone.annotations.**
-dontwarn androidx.work.impl.**
-dontwarn io.branch.referral.**
-dontwarn io.branch.indexing.**
-dontwarn io.flutter.view.**
-dontwarn io.flutter.plugin.**
-dontwarn com.razorpay.**
-dontwarn com.squareup.**


-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

-keepattributes JavascriptInterface
-keepattributes *Annotation*

-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}

-dontwarn com.squareup.**
-keep class com.squareup.** {*;}

-optimizations !method/inlining/*

-ignorewarnings
-keep class * {
    public private *;
}