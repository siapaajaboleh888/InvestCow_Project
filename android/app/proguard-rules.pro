# Flutter and common rules for release builds
-keep class io.flutter.app.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class androidx.lifecycle.** { *; }
-keep class androidx.core.** { *; }
-dontwarn kotlinx.coroutines.**
-dontwarn javax.annotation.**

# If you add libraries that use reflection, add their keep rules here.
