import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import java.net.URI
import java.security.MessageDigest
import java.util.Properties

plugins {
    alias(libs.plugins.androidApplication)
    alias(libs.plugins.composeCompiler)
}

kotlin {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_11
    }
}
dependencies {
    implementation(project(":app:shared"))

    implementation(libs.androidx.activity.compose)

    implementation(libs.compose.uiToolingPreview)
    debugImplementation(libs.compose.uiTooling)
}

// The key that signs every release the same way, from the ANDROID_KEYSTORE_PATH, ANDROID_KEYSTORE_PASSWORD, ANDROID_KEY_ALIAS and ANDROID_KEY_PASSWORD variables on GitHub or from the local keystore settings with the same key, and the debug key when neither is there.
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

android {
    namespace = "com.sumizuri.app"
    compileSdk = libs.versions.android.compileSdk
        .get()
        .toInt()

    defaultConfig {
        applicationId = "com.sumizuri.app"
        minSdk = libs.versions.android.minSdk
            .get()
            .toInt()
        targetSdk = libs.versions.android.targetSdk
            .get()
            .toInt()
        versionCode = providers.gradleProperty("app.versionCode").get().toInt()
        versionName = providers.gradleProperty("app.version").get()
    }
    // The texts of the app sit in one file that each text is read from at its own place, which a packed file has to unpack from the start for every text, on the thread that draws.
    androidResources {
        noCompress += "cvr"
    }
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
        // Native libraries are unpacked on install, so wireproxy is a file the app can run.
        jniLibs {
            useLegacyPackaging = true
        }
    }
    // One APK for each kind of processor, each with only its own native libraries, and one universal APK with all of them: arm64 for phones of the last years, armeabi-v7a for older 32-bit phones, and x86_64 and x86 for emulators and the few Intel devices. The app finds the one for its phone when it updates itself.
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
        // A debug build is its own app next to the release one, so installing it never replaces the release or its data.
        debug {
            applicationIdSuffix = ".debug"
            versionNameSuffix = "-debug"
        }
        release {
            signingConfig = signingConfigs.getByName(if (keystore != null) "release" else "debug")
            // The release is shrunk: code nothing calls is left out, the Material icons the app never draws among it, and so are the pictures and other resources nothing uses. Names are kept, see proguard-rules.pro.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
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

// wireproxy runs a WireGuard config inside the app, pinned to one release and its hash, and goes in as a native library for each kind of processor since Android only runs programs from that folder.
val wireproxyVersion = "v1.1.3"
val wireproxyAbis = mapOf(
    "arm64-v8a" to ("linux_arm64" to "370e00bd2167960d1ecd1c3c1439715bbaa94a0a110a2040468670c9af6021b6"),
    "armeabi-v7a" to ("linux_arm" to "19bbc5571f8f7a00e35f6f0d653201f25de2ce1a25659e4a45fb9e00929c954c"),
    "x86_64" to ("linux_amd64" to "e88c1d090740373fc606c1bafd81d9a5eadc642cce5667616e20e9d7a444f51c"),
    "x86" to ("linux_386" to "e24340318d5e9ea5f9e5746ec80370736d8712c76c5fa9868d449d69d2373244"),
)
val wireproxyLibs = layout.buildDirectory.dir("wireproxy-libs")

val fetchWireproxy = tasks.register("fetchWireproxy") {
    val version = wireproxyVersion
    val abis = wireproxyAbis
    val target = wireproxyLibs
    inputs.property("version", version)
    outputs.dir(target)
    doLast {
        fun hashOf(file: File) =
            MessageDigest.getInstance("SHA-256").digest(file.readBytes()).joinToString("") { "%02x".format(it) }
        for ((abi, build) in abis) {
            val (name, sha256) = build
            val address = "https://github.com/windtf/wireproxy/releases/download/$version/wireproxy_$name.tar.gz"
            val archive = temporaryDir.resolve(address.substringAfterLast('/'))
            if (!archive.isFile || hashOf(archive) != sha256) {
                logger.lifecycle("Fetching $address")
                URI(address).toURL().openStream().use { input -> archive.outputStream().use { input.copyTo(it) } }
            }
            val found = hashOf(archive)
            if (found != sha256) {
                archive.delete()
                throw GradleException("$address has the hash $found, not the pinned $sha256, so it is not used.")
            }
            val folder = target
                .get()
                .asFile
                .resolve(abi)
                .apply { mkdirs() }
            // The tar of the system takes the program out, which Windows, Linux and a Mac all have.
            val run = ProcessBuilder(
                "tar",
                "-xzf",
                archive.absolutePath,
                "-C",
                folder.absolutePath,
                "wireproxy",
            ).redirectErrorStream(true).start()
            val said = run.inputStream.bufferedReader().readText()
            val program = folder.resolve("wireproxy")
            if (run.waitFor() != 0 ||
                !program.isFile
            ) {
                throw GradleException("wireproxy could not be taken out of the release: $said")
            }
            program.copyTo(folder.resolve("libwireproxy.so"), overwrite = true)
            program.delete()
        }
    }
}

android.sourceSets
    .getByName("main")
    .jniLibs.directories
    .add(wireproxyLibs.get().asFile.path)
tasks.named("preBuild") { dependsOn(fetchWireproxy) }
