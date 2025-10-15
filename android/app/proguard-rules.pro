# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.embedding.**  { *; }

# Google Play Core
-keep class com.google.android.play.core.** { *; }
-keep interface com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Dio and related classes
-keep class com.squareup.okhttp.** { *; }
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-keep class com.google.gson.** { *; }
-keep class com.squareup.moshi.** { *; }

# Keep Riverpod and related classes
-keep class com.sumwarehouse.** { *; }

# Keep Json serialization
-keep class com.google.gson.Gson { *; }
-keep class com.google.gson.GsonBuilder { *; }
-keep class com.google.gson.annotations.** { *; }

# Keep Freezed classes
-keep class **.*Freezed { *; }
-keep class **.*FreezedBuilder { *; }

# Keep all classes in data models
-keep class **.model.** { *; }
-keep class **.entity.** { *; }
-keep class **.dto.** { *; }

# Keep all classes with @JsonSerializable annotation
-keep @com.google.gson.annotations.JsonAdapter class * { *; }
-keep @com.google.gson.annotations.SerializedName class * { *; }

# General Flutter obfuscation rules
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# Keep all classes that might be used in reflection
-keep class ** implements java.io.Serializable { *; }
-keep class ** implements android.os.Parcelable { *; }

# For file operations
-keep class java.io.File { *; }
-keep class java.io.FileInputStream { *; }
-keep class java.io.FileOutputStream { *; }
-keep class java.io.IOException { *; }

# Keep SharedPreferences and SecureStorage
-keep class android.content.SharedPreferences { *; }
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# Keep permission handler classes
-keep class com.baseflow.permissionhandler.** { *; }

# Keep URL launcher
-keep class com.baseflow.url_launcher.** { *; }

# Keep file picker
-keep class com.mr.flutter.plugin.filepicker.** { *; }
