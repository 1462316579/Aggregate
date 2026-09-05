## ProGuard rules for AllPlay
-keep class com.allplay.app.** { *; }
-keep class io.flutter.** { *; }

# media_kit
-keep class com.alexvas.dvr.** { *; }
-keep class com.google.android.exoplayer2.** { *; }

# 禁止混淆 Spider 解析类
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses

# JSON 序列化
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}
