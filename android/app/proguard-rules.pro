# Keep Python classes
-keep class com.chaquo.python.** { *; }

# Keep ML model classes
-keep class org.tensorflow.** { *; }

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep enums
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
