# flutter_js's Android QuickJS binding is a third-party JNI bridge with no bundled
# consumer rules, so keep it and its native runtime library from being renamed/stripped.
-keep class io.abner.flutter_js.** { *; }
-keep class com.fastdev.** { *; }
-keep class * extends java.lang.Exception

# sqlite3's native bindings resolve methods by name from native code.
-keep class io.tekartik.sqflite.** { *; }
-keepclasseswithmembernames class * {
    native <methods>;
}
