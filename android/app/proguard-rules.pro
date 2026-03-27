# Proguard rules for Job Search app performance optimization

# Keep Flutter-related classes
-keep class io.flutter.** { *; }
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep all native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep custom application classes
-keep class com.example.job_search.** { *; }

# HTTP client optimization
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# JSON parsing optimization
-keepclassmembers class * {
  *** fromJson(...);
}

# Serialization
-keep class * implements java.io.Serializable { *; }

# Remove logging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
}

# Aggressive optimization flags
-optimizationpasses 5
-dontusemixedcaseclassnames
-verbose
-optimizations !code/simplification/cast,!field/*,!class/merging/*

# Keep line numbers for crash reporting
-keepattributes SourceFile,LineNumberTable
-renamesourcefileattribute SourceFile
