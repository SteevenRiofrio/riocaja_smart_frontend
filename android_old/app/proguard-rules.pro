# Google ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }

# Keep all Google ML Kit text recognition classes
-keep class com.google.mlkit.vision.text.** { *; }
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.japanese.**
-dontwarn com.google.mlkit.vision.text.korean.**

# Firebase ML Kit
-keep class com.google.firebase.ml.** { *; }
-dontwarn com.google.firebase.ml.**

# Camera
-keep class androidx.camera.** { *; }
-dontwarn androidx.camera.**