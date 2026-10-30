# Rules for shrinking the desktop release. Only code nothing calls is dropped from the libraries, and every name stays as it is, so code reached by name still finds it.
-dontobfuscate
-dontoptimize

# Libraries point at optional parts the app does not ship, which is normal for them and not an error.
-ignorewarnings
-dontnote **

# The code of the app stays whole, as the database, the serializers, the script engine and the calls into Windows reach it by name.
-keep class com.sumizuri.** { *; }

# Libraries that call native code or are called from it.
-keep class com.sun.jna.** { *; }
-keep class * implements com.sun.jna.Library { *; }
-keep class * implements com.sun.jna.Callback { *; }
-keep class * extends com.sun.jna.Structure { *; }
-keep class androidx.sqlite.** { *; }
-keep class com.dokar.quickjs.** { *; }
-keep class org.cef.** { *; }
-keep class dev.datlag.kcef.** { *; }
-keep class com.jogamp.** { *; }
-keep class jogamp.** { *; }
-keep class com.jetbrains.** { *; }

# Libraries that find their own parts by name or through service files.
-keep class androidx.room3.** { *; }
-keep class com.jcraft.jsch.** { *; }
-keep class okhttp3.** { *; }
-keep class okio.** { *; }
-keep class io.ktor.** { *; }
-keep class coil3.** { *; }
-keep class dev.whyoleg.cryptography.** { *; }
-keep class kotlinx.coroutines.** { *; }
-keep class kotlinx.serialization.** { *; }
-keep class androidx.lifecycle.** { *; }
-keep class androidx.savedstate.** { *; }
-keep class org.slf4j.** { *; }
-keep class com.fleeksoft.** { *; }

# What Kotlin, the serializers and the lifecycle read about classes while the app runs.
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod,Exceptions,RuntimeVisible*Annotations,KotlinMetadata

# The texts of the app are read from their place in one file, which only stays quick when that file is not packed.
-dontcompress **.cvr
