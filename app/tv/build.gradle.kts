import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import java.util.Properties

plugins {
    alias(libs.plugins.androidApplication)
    alias(libs.plugins.composeCompiler)
}

// The app for TVs. It is built from the same code as the app for phones, with its own id, name in the launcher and manifest, so a TV gets an app made only for it and a phone app never shows in the launcher of a TV.
kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_11
    }
}
dependencies {
    implementation(project(":app:shared"))

    implementation(libs.androidx.activity.compose)
    implementation(libs.androidx.core.splashscreen)
}

// The same key as the app for phones, so both are signed alike.
val keystore: Map<String, String>? = System.getenv("ANDROID_KEYSTORE_PATH")?.let { path ->
    mapOf(
        "storeFile" to path,
        "storePassword" to System.getenv("ANDROID_KEYSTORE_PASSWORD").orEmpty(),
        "keyAlias" to System.getenv("ANDROID_KEY_ALIAS").orEmpty(),
        "keyPassword" to System.getenv("ANDROID_KEY_PASSWORD").orEmpty(),
    )
} ?: rootProject.file("keystore.properties").takeIf { it.exists() }?.let { file ->
    val saved = Properties().apply { file.inputStream().use { load(it) } }
    saved.stringPropertyNames().associateWith { saved.getProperty(it) }
}

// The code and the pictures of the Android app it shares with the app for phones.
val phone = rootProject.file("app/android/src")

android {
    // The same name space as the app for phones, as the code it shares reads its resources by it.
    namespace = "com.sumizuri.app"
    compileSdk = libs.versions.android.compileSdk
        .get()
        .toInt()

    defaultConfig {
        applicationId = "com.sumizuri.app.tv"
        minSdk = libs.versions.android.minSdk
            .get()
            .toInt()
        targetSdk = libs.versions.android.targetSdk
            .get()
            .toInt()
        versionCode = providers.gradleProperty("app.versionCode").get().toInt()
        versionName = providers.gradleProperty("app.version").get()
    }
    androidResources {
        noCompress += "cvr"
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
        jniLibs {
            useLegacyPackaging = true
        }
    }
    // TV boxes run arm64 or older 32-bit arm, and emulators x86_64 or x86.
    splits {
        abi {
            isEnable = true
            reset()
            include("arm64-v8a", "armeabi-v7a", "x86_64", "x86")
            isUniversalApk = true
        }
    }
    signingConfigs {
        if (keystore != null) {
            create("release") {
                storeFile = rootProject.file(keystore.getValue("storeFile"))
                storePassword = keystore.getValue("storePassword")
                keyAlias = keystore.getValue("keyAlias")
                keyPassword = keystore.getValue("keyPassword")
            }
        }
    }
    buildTypes {
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
        release {
            signingConfig = signingConfigs.getByName(if (keystore != null) "release" else "debug")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                phone.resolve("../proguard-rules.pro"),
            )
        }
    }
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    buildFeatures {
        compose = true
    }
}

android.sourceSets.getByName("main") {
    manifest.srcFile("src/main/AndroidManifest.xml")
    kotlin.directories.add(phone.resolve("main/kotlin").path)
    res.directories.add(phone.resolve("main/res").path)
    // wireproxy comes from the app for phones, which fetches it.
    jniLibs.directories.add(
        project(":app:android")
            .layout.buildDirectory
            .dir("wireproxy-libs")
            .get()
            .asFile.path,
    )
}
android.sourceSets.getByName("debug") {
    manifest.srcFile(phone.resolve("debug/AndroidManifest.xml"))
    res.directories.add(phone.resolve("debug/res").path)
}
tasks.named("preBuild") { dependsOn(":app:android:fetchWireproxy") }
