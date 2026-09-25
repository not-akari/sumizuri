plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.sumizuri.sumizuri"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    // The release "lint vital" pass opens files in the build folder that another Gradle process (Android Studio, a debug run) can still hold on Windows, and then the whole release build fails. Lint still runs in the IDE.
    lint {
        checkReleaseBuilds = false
    }

    compileOptions {
        // The notifications plugin needs newer Java library classes than older Android versions have.
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.sumizuri.sumizuri"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        manifestPlaceholders["appLabel"] = "Sumizuri"
    }

    // Release CI signs with a key kept in GitHub secrets, so every release carries the same signature and can update the last one.
    val ciKeystorePath = System.getenv("ANDROID_KEYSTORE_PATH")
    if (ciKeystorePath != null) {
        signingConfigs {
            create("ci") {
                storeFile = file(ciKeystorePath)
                storePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
                keyAlias = System.getenv("ANDROID_KEY_ALIAS")
                keyPassword = System.getenv("ANDROID_KEY_PASSWORD")
            }
        }
    }

    // A release APK normally stores its native libraries uncompressed, so Android can read them straight from the file. Compressing them makes the download about half the size, and the phone then unpacks them into its own storage on install. CI turns this on for the APKs it publishes; a local build keeps the default.
    packaging {
        jniLibs {
            useLegacyPackaging = System.getenv("COMPRESS_NATIVE_LIBS") == "true"
        }
    }

    buildTypes {
        // A debug build is a different app to Android: its own id, name and data, so running it never replaces or touches the installed release.
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
            manifestPlaceholders["appLabel"] = "Sumizuri Debug"
        }
        release {
            // Local builds fall back to the debug key so `flutter run --release` works.
            signingConfig = if (ciKeystorePath != null) signingConfigs.getByName("ci") else signingConfigs.getByName("debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
