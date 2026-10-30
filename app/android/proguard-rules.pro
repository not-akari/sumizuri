# Rules for shrinking the release. The release drops the code nothing calls, but keeps every name as it is: the database, the network, the script engine and the saved choices reach parts of the app and of its libraries by their names, and renaming them is where shrinking usually breaks an app. The libraries bring their own rules for the rest.
-dontobfuscate

# Room makes each database by finding its generated class by name and calling the empty constructor, both for the database of the app and for the one WorkManager keeps for the background checks.
-keep class * extends androidx.room.RoomDatabase { <init>(); }
-keep class * extends androidx.room3.RoomDatabase { <init>(); }

# JSch, which runs the SSH tunnel, picks its ciphers, key exchanges and key types from lists of class names, and the tunnel widens the window of a channel through methods it reaches by name. None of it may be dropped. The optional libraries JSch can use instead of its own code, and the Kerberos sign in Android does not have, are not in the app.
-keep class com.jcraft.jsch.** { *; }
-dontwarn org.ietf.jgss.**
-dontwarn org.bouncycastle.**
-dontwarn org.newsclub.net.unix.**
-dontwarn com.sun.jna.**
-dontwarn org.apache.logging.log4j.**
-dontwarn org.slf4j.**

# PdfBox, which reads the words of PDF books, finds its font and filter classes by name and leaves out the JPEG 2000 reader on purpose.
-keep class com.tom_roush.** { *; }
-dontwarn com.gemalto.jp2.**
