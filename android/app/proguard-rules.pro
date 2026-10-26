# Canary Duress Lock — ProGuard Rules
-keep class com.canary.duresslock.** { *; }
-keep class io.flutter.** { *; }
-keep class androidx.biometric.** { *; }
# Preserve KeyStoreManager for native channel calls
-keep class com.canary.duresslock.security.KeyStoreManager { *; }
-keep class com.canary.duresslock.security.MemoryZeroizer { *; }
-keep class com.canary.duresslock.security.DuressTriggerReceiver { *; }
-keep class com.canary.duresslock.security.CanaryDeviceAdminReceiver { *; }
# Keep Flutter embedding + generated plugin registrant
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**
