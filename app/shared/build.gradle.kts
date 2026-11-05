import org.jetbrains.kotlin.gradle.dsl.JvmTarget
import org.jetbrains.kotlin.gradle.plugin.KotlinPlatformType
import java.util.Locale

plugins {
    alias(libs.plugins.kotlinMultiplatform)
    alias(libs.plugins.androidMultiplatformLibrary)
    alias(libs.plugins.composeMultiplatform)
    alias(libs.plugins.composeCompiler)
    alias(libs.plugins.ksp)
    alias(libs.plugins.kotlinSerialization)
    alias(libs.plugins.androidxRoom3)
}

room3 {
    // Exported schema files, kept in the project so migrations can be checked later.
    schemaDirectory("$projectDir/schemas")
}

kotlin {
    jvm()

    // The desktop and Android both run on Java, so what uses the networking of Java is written once in jvmSharedMain.
    applyDefaultHierarchyTemplate {
        common {
            group("jvmShared") {
                withJvm()
                withCompilations { it.target.platformType == KotlinPlatformType.androidJvm }
            }
        }
    }

    // The iPhone and iPad, and their simulator on an Apple silicon Mac. The app is built into one framework that the project in iosApp opens.
    listOf(iosArm64(), iosSimulatorArm64()).forEach { target ->
        target.binaries.framework {
            baseName = "Shared"
            isStatic = true
        }
    }

    compilerOptions {
        freeCompilerArgs.add("-Xexpect-actual-classes")
    }

    android {
        namespace = "com.sumizuri.app.shared"
        compileSdk = libs.versions.android.compileSdk
            .get()
            .toInt()
        minSdk = libs.versions.android.minSdk
            .get()
            .toInt()

        compilerOptions {
            jvmTarget = JvmTarget.JVM_11
        }
        androidResources {
            enable = true
        }
    }

    sourceSets {
        getByName("jvmSharedMain").dependencies {
            implementation(libs.jsch)
            implementation(libs.zxing)
        }
        androidMain.dependencies {
            implementation(libs.ktor.client.okhttp)
            implementation(libs.kotlinx.coroutinesAndroid)
            implementation(libs.compose.uiToolingPreview)
            implementation(libs.compose.uiTooling)
            implementation(libs.androidx.activity.compose)
            implementation(libs.androidx.webkit)
            implementation(libs.androidx.work)
            implementation(libs.media3.exoplayer)
            implementation(libs.media3.hls)
            implementation(libs.media3.okhttp)
            implementation(libs.media3.ui)
        }
        commonMain.dependencies {
            implementation(libs.compose.runtime)
            implementation(libs.compose.foundation)
            implementation(libs.compose.material3)
            implementation(libs.compose.materialIcons)
            implementation(libs.compose.ui)
            implementation(libs.navigationevent.compose)
            implementation(libs.androidx.lifecycle.viewmodelCompose)
            implementation(libs.androidx.lifecycle.runtimeCompose)
            implementation(libs.kotlinx.coroutinesCore)
            api(libs.androidx.room3.runtime)
            implementation(libs.androidx.sqlite.bundled)
            implementation(libs.kotlinx.serialization.json)
            implementation(libs.compose.resources)
            implementation(libs.quickjs)
            implementation(libs.ksoup)
            implementation(libs.ktor.client.core)
            // The formats and keys of sync, shared with the sync server.
            implementation(project(":sync:core"))
            implementation(libs.cryptography.core)
            implementation(libs.cryptography.provider)
            api(libs.okio)
            implementation(libs.coil.compose)
            implementation(libs.coil.network.ktor)
            // Draws the QR code an authenticator app scans to set up two-step sign in.
            implementation(libs.qrose)
        }
        iosMain.dependencies {
            implementation(libs.ktor.client.darwin)
        }
        jvmMain.dependencies {
            implementation(libs.ktor.client.okhttp)
            implementation(libs.kcef)
            // Plays video through libmpv, which comes with the app on Windows and is the one the system has elsewhere, called through JNA.
            implementation(libs.jna)
            // The embedded browser draws off screen through these native libraries, one set for each desktop system.
            for (system in listOf("windows-amd64", "linux-amd64", "macosx-universal")) {
                runtimeOnly("org.jogamp.gluegen:gluegen-rt:2.5.0:natives-$system")
                runtimeOnly("org.jogamp.jogl:jogl-all:2.5.0:natives-$system")
            }
        }
    }
}

dependencies {
    androidRuntimeClasspath(libs.compose.uiTooling)
    add("kspAndroid", libs.androidx.room3.compiler)
    add("kspJvm", libs.androidx.room3.compiler)
    add("kspIosArm64", libs.androidx.room3.compiler)
    add("kspIosSimulatorArm64", libs.androidx.room3.compiler)
}

// The version and the address of the releases from the project settings, written into a small Kotlin file so the screens can show them and the updater can check them.
val generateBuildInfo = tasks.register("generateBuildInfo") {
    val version = providers.gradleProperty("app.version")
    val updateRepo = providers.gradleProperty("app.updateRepo").orElse("")
    val folder = layout.buildDirectory.dir("generated/buildInfo")
    inputs.property("version", version)
    inputs.property("updateRepo", updateRepo)
    outputs.dir(folder)
    doLast {
        val file = folder.get().file("com/sumizuri/app/BuildInfo.kt").asFile
        file.parentFile.mkdirs()
        file.writeText(
            "package com.sumizuri.app\n\n// Written by the build.\nobject BuildInfo {\n    const val Version = \"${version.get()}\"\n\n    // The GitHub or GitLab repo whose releases the updater checks, empty until one is set.\n    const val UpdateRepo = \"${updateRepo.get()}\"\n}\n",
        )
    }
}

// The languages the app is translated into, found from the folders of its words, such as values-es or values-pt-rBR, each with its name in its own language. A translation added from Weblate then shows in the choice of language without a change to the code.
val generateLanguages = tasks.register("generateLanguages") {
    val words = layout.projectDirectory.dir("src/commonMain/composeResources")
    val folder = layout.buildDirectory.dir("generated/languages")
    inputs.files(fileTree(words) { include("values-*/strings.xml") })
    outputs.dir(folder)
    doLast {
        val qualifier = Regex("^values-([a-z]{2,3})(?:-r([A-Z]{2}))?$")
        val found = words.asFile
            .listFiles()
            .orEmpty()
            .filter { it.isDirectory && File(it, "strings.xml").isFile }
            .mapNotNull { qualifier.find(it.name) }
            .map { match ->
                listOf(
                    match.groupValues[1],
                    match.groupValues[2],
                ).filter { it.isNotEmpty() }.joinToString("-")
            }.map { tag ->
                val locale = Locale.forLanguageTag(tag)
                tag to locale.getDisplayName(locale).replaceFirstChar { it.titlecase(locale) }
            }.sortedBy { it.second }
        val lines = found.joinToString("") { (tag, name) -> "    \"$tag\" to \"$name\",\n" }
        val file = folder.get().file("com/sumizuri/app/ui/language/TranslatedLanguages.kt").asFile
        file.parentFile.mkdirs()
        file.writeText(
            "package com.sumizuri.app.ui.language\n\n// Written by the build from the folders of the words, as the code of each language and its own name.\ninternal val TranslatedLanguages: List<Pair<String, String>> = listOf(\n$lines)\n",
        )
    }
}

kotlin.sourceSets.commonMain {
    kotlin.srcDir(generateBuildInfo)
    kotlin.srcDir(generateLanguages)
}

// The desktop jar is kept unpacked. Each text of the app is read from its place in one file, and in a packed jar that meant unpacking the file from the start for every text, with the window waiting. Unpacked classes also load quicker, and the installers pack everything anyway.
tasks.named<Jar>("jvmJar") {
    entryCompression = ZipEntryCompression.STORED
}

compose.resources {
    packageOfResClass = "com.sumizuri.app.shared.resources"
    publicResClass = false
}
