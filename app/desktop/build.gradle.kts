import org.jetbrains.compose.desktop.application.dsl.TargetFormat
import org.jetbrains.compose.desktop.application.tasks.AbstractJLinkTask
import org.jetbrains.compose.desktop.application.tasks.AbstractJPackageTask
import java.net.URI
import java.security.MessageDigest
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream

plugins {
    alias(libs.plugins.kotlinJvm)
    alias(libs.plugins.composeMultiplatform)
    alias(libs.plugins.composeCompiler)
}

dependencies {
    implementation(project(":app:shared"))

    implementation(compose.desktop.currentOs)
    implementation(libs.kotlinx.coroutinesSwing)
    // Lets the window bar move the window with calls of Windows, which follow a fast mouse where moves done once per frame lagged.
    implementation(libs.jna)

    implementation(libs.compose.uiToolingPreview)
}

apply(from = "signatures.gradle.kts")
apply(from = "natives.gradle.kts")

// Where the files that go with the app are put, by system, as the installers want them.
val mpvRoot = layout.buildDirectory.dir("app-resources")

// libmpv for Windows, pinned to one build of shinchiro/mpv-winbuild-cmake, the builds the mpv site points to, and checked against the hash it had when it was chosen. The build comes as a 7z archive, so the small extractor of 7-Zip, pinned and checked the same way, takes libmpv out of it. A newer build is taken by changing its address and hash together.
val mpvBuild = "https://github.com/shinchiro/mpv-winbuild-cmake/releases/download/20261010/mpv-dev-x86_64-20261010-git-b2c255c13e.7z"
val mpvSha256 = "394490ed6354c2294b87c63dfa3663b23524b5551aace9cbe35c4085682b14fa"
val sevenZip = "https://github.com/ip7z/7zip/releases/download/26.04/7zr.exe"
val sevenZipSha256 = "256feca8e274e5da655e2a284fabafd9f554365eb164862089dacd4e8276d282"
val mpvLibrary = "libmpv-2.dll"
// A small libmpv built by our own script and given as a path through its Gradle property, which the release uses in place of the full build. The folder of the project is passed in, not read from the script, so the configuration cache can keep the result.
val mpvBuilt = rootProject.projectDir.let { root ->
    providers.gradleProperty("mpv.dll").map { path -> File(path).let { if (it.isAbsolute) it else root.resolve(path) }.absolutePath }
}

// Fetches the build and the extractor once, checks both, and takes libmpv into the folder of the files of the app, where a run and an installer both find it. Only a Windows computer needs it, and only a Windows computer can run the extractor.
val fetchLibmpv = tasks.register("fetchLibmpv") {
    val target = mpvRoot.map { it.dir("windows") }
    // What the step needs is copied here, as the configuration cache keeps a step without the script it was written in.
    val build = mpvBuild
    val buildSha256 = mpvSha256
    val extractorAddress = sevenZip
    val extractorSha256 = sevenZipSha256
    val library = mpvLibrary
    val built = mpvBuilt
    inputs.property("build", build)
    inputs.property("sha256", buildSha256)
    inputs.property("built", built.orElse(""))
    outputs.dir(target)
    onlyIf { System.getProperty("os.name").lowercase().contains("win") }
    doLast {
        // A libmpv built here is taken as it is.
        built.orNull?.let { path ->
            val folder = target.get().asFile.apply { mkdirs() }
            File(path).copyTo(folder.resolve(library), overwrite = true)
            return@doLast
        }
        fun hashOf(file: File) = MessageDigest.getInstance("SHA-256").digest(file.readBytes()).joinToString("") { "%02x".format(it) }
        // Keeps a file that has the pinned hash, fetching it again when it is missing or changed.
        fun pinned(address: String, sha256: String): File {
            val file = temporaryDir.resolve(address.substringAfterLast('/'))
            if (!file.isFile || hashOf(file) != sha256) {
                logger.lifecycle("Fetching $address")
                URI(address).toURL().openStream().use { input -> file.outputStream().use { input.copyTo(it) } }
            }
            val found = hashOf(file)
            if (found != sha256) {
                file.delete()
                throw GradleException("$address has the hash $found, not the pinned $sha256, so it is not used.")
            }
            return file
        }
        val archive = pinned(build, buildSha256)
        val extractor = pinned(extractorAddress, extractorSha256)
        val folder = target.get().asFile.apply { mkdirs() }
        val run = ProcessBuilder(extractor.absolutePath, "e", archive.absolutePath, "-o${folder.absolutePath}", library, "-r", "-y").redirectErrorStream(true).start()
        val said = run.inputStream.bufferedReader().readText()
        if (run.waitFor() != 0 || !folder.resolve(library).isFile) throw GradleException("libmpv could not be taken out of the build: $said")
    }
}

// wireproxy, which runs a WireGuard config inside the app, pinned to one release of windtf/wireproxy and checked against the hash the release lists. It goes beside libmpv, where a run and an installer both find it. A newer release is taken by changing the version and the hashes together.
val wireproxyVersion = "v1.1.3"
val wireproxyBuilds = mapOf(
    "windows_amd64" to "bce041ea9fe0f8a3351301dcbe29cdf6a523bb25cf9c62f17ebb5699a8051d0f",
    "linux_amd64" to "e88c1d090740373fc606c1bafd81d9a5eadc642cce5667616e20e9d7a444f51c",
    "linux_arm64" to "370e00bd2167960d1ecd1c3c1439715bbaa94a0a110a2040468670c9af6021b6",
)

val fetchWireproxy = tasks.register("fetchWireproxy") {
    val system = System.getProperty("os.name").lowercase()
    val arm = System.getProperty("os.arch").lowercase().let { "aarch64" in it || "arm64" in it }
    val build = when {
        "win" in system -> "windows_amd64"
        "linux" in system -> if (arm) "linux_arm64" else "linux_amd64"
        else -> null
    }
    val sha256 = build?.let { wireproxyBuilds[it] }
    val address = "https://github.com/windtf/wireproxy/releases/download/$wireproxyVersion/wireproxy_$build.tar.gz"
    val program = if (build?.startsWith("windows") == true) "wireproxy.exe" else "wireproxy"
    val target = mpvRoot.map { it.dir(if (build?.startsWith("windows") == true) "windows" else "linux") }
    inputs.property("address", address)
    outputs.dir(target)
    onlyIf { sha256 != null }
    doLast {
        fun hashOf(file: File) = MessageDigest.getInstance("SHA-256").digest(file.readBytes()).joinToString("") { "%02x".format(it) }
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
        val folder = target.get().asFile.apply { mkdirs() }
        // The tar of the system takes the program out, which Windows and Linux both have.
        val run = ProcessBuilder("tar", "-xzf", archive.absolutePath, "-C", folder.absolutePath, program).redirectErrorStream(true).start()
        val said = run.inputStream.bufferedReader().readText()
        if (run.waitFor() != 0 || !folder.resolve(program).isFile) throw GradleException("wireproxy could not be taken out of the release: $said")
        folder.resolve(program).setExecutable(true)
    }
}

// The picture the launcher shows while the app starts, in light and dark and in each size Java picks by the scale of the screen. The dark one is in place at first, and the app swaps in the one that matches Windows.
val copySplash = tasks.register<Copy>("copySplash") {
    from("splash")
    from("splash") {
        include("splash-dark*.png")
        rename { it.replace("splash-dark", "splash") }
    }
    into(mpvRoot.map { it.dir("common") })
}

// The installers take the files of the app once libmpv, wireproxy and the picture are there.
tasks.matching { it.name == "prepareAppResources" }.configureEach { dependsOn(fetchLibmpv, fetchWireproxy, copySplash) }

compose.desktop {
    application {
        mainClass = "com.sumizuri.app.MainKt"
        // The embedded browser, used for pages behind a bot check, needs these opened on a modern JDK.
        jvmArgs("--add-opens", "java.desktop/sun.awt=ALL-UNNAMED", "--add-opens", "java.desktop/java.awt.peer=ALL-UNNAMED")
        // On a Mac the embedded browser also reaches into the window code of Apple, which a modern JDK keeps closed.
        if (System.getProperty("os.name").lowercase().contains("mac")) {
            jvmArgs("--add-opens", "java.desktop/sun.lwawt=ALL-UNNAMED", "--add-opens", "java.desktop/sun.lwawt.macosx=ALL-UNNAMED")
        }
        // Memory for a desktop app: a heap that starts small and stops at 1 GB, and the usual collector of Java, which clears old objects alongside the app instead of stopping it for each full pass, with two threads for its work and the memory it no longer needs given back after a minute of quiet. Text that repeats, such as the names and addresses of titles and chapters, is kept once. The simple collector used before, squeezed down to the memory in use, stopped the app for a full pass every few seconds, which showed as a stutter.
        jvmArgs("-Xms64m", "-Xmx1g", "-XX:+UseG1GC", "-XX:ParallelGCThreads=2", "-XX:ConcGCThreads=1", "-XX:G1PeriodicGCInterval=60000", "-XX:+UseStringDeduplication")

        // The release drops the code of its libraries that nothing calls, which makes the installer, the first start and the archive of classes smaller. Names are never changed, and the libraries that reach their code by name are kept whole, as the rules list.
        buildTypes.release.proguard {
            isEnabled.set(true)
            obfuscate.set(false)
            optimize.set(false)
            configurationFiles.from(project.file("proguard-rules.pro"))
        }

        nativeDistributions {
            // The files that go with the app. On Windows that is libmpv, which plays the video.
            appResourcesRootDir.set(mpvRoot)
            // The parts of Java the app uses: the window and its accessibility, the network and its encryption, the character sets and the formats of each language, the counters of the performance page, and the flight recorder for measuring a slow app. Java's own tools, its second compiler and JavaFX, which the app never uses, stay out, and they were most of the size of the runtime.
            modules(
                "java.base", "java.desktop", "java.instrument", "java.logging", "java.management", "java.naming", "java.net.http", "java.sql",
                "jdk.accessibility", "jdk.charsets", "jdk.crypto.ec", "jdk.jfr", "jdk.localedata", "jdk.management",
                "jdk.management.jfr", "jdk.net", "jdk.unsupported", "jdk.unsupported.desktop", "jdk.zipfs",
            )
            // The certificate store of Windows, which only a Java for Windows has.
            if (System.getProperty("os.name").lowercase().contains("win")) modules("jdk.crypto.mscapi")
            targetFormats(TargetFormat.Dmg, TargetFormat.Msi, TargetFormat.Exe, TargetFormat.Deb)
            // The name the installed app goes by in the start menu and the list of apps.
            packageName = "Sumizuri"
            vendor = "Sumizuri"
            // The icon of the installed app, a different format for each system.
            windows {
                iconFile.set(project.file("icons/app-icon.ico"))
                // Never changes, so a newer installer updates the installed app instead of adding a second one.
                upgradeUuid = "002e383e-74a1-485e-a9f9-0a0ee4113658"
                // Installs for the person only, so it needs no administrator, and adds a start menu entry and a desktop shortcut.
                perUserInstall = true
                menu = true
                menuGroup = "Sumizuri"
                shortcut = true
                dirChooser = true
            }
            macOS {
                iconFile.set(project.file("icons/app-icon.icns"))
                bundleID = "com.sumizuri.app"
                dockName = "Sumizuri"
                minimumSystemVersion = "12.0"
                // The links that start with sumizuri:, such as the Open in Sumizuri button on the page of a repo, open the app.
                infoPlist {
                    extraKeysRawXml = """
                        <key>CFBundleURLTypes</key>
                        <array>
                            <dict>
                                <key>CFBundleURLName</key>
                                <string>com.sumizuri.app</string>
                                <key>CFBundleURLSchemes</key>
                                <array>
                                    <string>sumizuri</string>
                                </array>
                            </dict>
                        </array>
                    """.trimIndent()
                }
                // Signed and notarized only when the release is given the certificate of an Apple developer account. Without it the app is not signed, and a Mac asks the person to allow it once.
                val identity = providers.environmentVariable("MAC_SIGN_IDENTITY").orNull?.takeIf { it.isNotBlank() }
                if (identity != null) {
                    signing {
                        sign.set(true)
                        this.identity.set(identity)
                    }
                    notarization {
                        appleID.set(providers.environmentVariable("MAC_NOTARY_APPLE_ID"))
                        password.set(providers.environmentVariable("MAC_NOTARY_PASSWORD"))
                        teamID.set(providers.environmentVariable("MAC_NOTARY_TEAM_ID"))
                    }
                }
            }
            linux {
                iconFile.set(project.file("icons/app-icon.png"))
                // A Linux package name must be lower case.
                packageName = "sumizuri"
                // Adds the app to the menu of apps.
                shortcut = true
                menuGroup = "Sumizuri"
                appCategory = "Graphics"
            }
            // The installers refuse a version that starts with 0 and take only numbers, so 0.1.0 is packaged as 1.1.0 and a suffix such as beta is left out.
            packageVersion = providers.gradleProperty("app.version").get().substringBefore('-').replace(Regex("^0\\."), "1.")
        }
    }
}

// A full Java comes with an archive of its own classes, which lets them start without being read and checked one by one, but jlink leaves it out. The java command of the same Java is put in to make it, and stays, since the installed app uses it to make the archive of its own classes.
tasks.withType<AbstractJLinkTask>().configureEach {
    val image = destinationDir
    val jdk = javaHome
    doLast {
        val windows = System.getProperty("os.name").lowercase().contains("win")
        val launcher = if (windows) "java.exe" else "java"
        val added = image.get().asFile.resolve("bin/$launcher")
        File(jdk.get(), "bin/$launcher").copyTo(added, overwrite = true)
        added.setExecutable(true)
        val run = ProcessBuilder(added.absolutePath, "-Xshare:dump").redirectErrorStream(true).start()
        val said = run.inputStream.bufferedReader().readText()
        if (run.waitFor() != 0) throw GradleException("The class archive of the runtime could not be made: $said")
        // Java makes the archive read only, which on Windows stops the next build and the installer from replacing it.
        image.get().asFile.walk().filter { it.name.endsWith(".jsa") }.forEach { it.setWritable(true) }
    }
}

// The installed app reads the archive of its own classes from next to its files once the app has made it in the background. Java is never asked to make one while the app runs, as that made the whole first run after an update many times slower. It is added once Compose has set the options of the app, which would replace it otherwise.
afterEvaluate {
    tasks.withType<AbstractJPackageTask>().configureEach {
        launcherJvmArgs.addAll("-XX:SharedArchiveFile=\$APPDIR/sumizuri.jsa", "-splash:\$APPDIR/resources/splash.png")
        // A Linux package installs where only root can write, so its own install script makes the archive, and its removal script takes it away. The folder of the scripts is named after the one Compose gives, and the packager takes the last.
        if (System.getProperty("os.name").lowercase().contains("linux")) {
            freeArgs.addAll("--resource-dir", file("packaging/linux").absolutePath)
        }
    }
}

// Makes the release folder smaller before it goes into the Windows installer, keeping only the Material icons the code names.
val shrinkReleaseImage = tasks.register("shrinkReleaseImage") {
    dependsOn("createReleaseDistributable")
    val folder = layout.buildDirectory.dir("compose/binaries/main-release/app/Sumizuri/app")
    onlyIf { System.getProperty("os.name").lowercase().contains("win") }
    doLast {
        val dir = folder.get().asFile
        // Writes a jar again with only the entries kept, in place.
        fun rewrite(jar: File, keep: (String) -> Boolean) {
            val kept = File(jar.path + ".tmp")
            ZipFile(jar).use { zip ->
                ZipOutputStream(kept.outputStream().buffered()).use { out ->
                    for (entry in zip.entries()) {
                        if (!keep(entry.name)) continue
                        out.putNextEntry(ZipEntry(entry.name).apply { time = entry.time })
                        zip.getInputStream(entry).use { it.copyTo(out) }
                        out.closeEntry()
                    }
                }
            }
            jar.delete()
            kept.renameTo(jar)
        }
        val before = dir.walkTopDown().filter { it.isFile }.sumOf { it.length() }
        // The native files of other systems already left the jars right after the shrinking.
        val jars = dir.listFiles { file -> file.name.endsWith(".jar") }.orEmpty().toList()
        // The icons the code of the app and of its libraries names, as classes such as androidx/compose/material/icons/outlined/PaletteKt.
        val icons = jars.firstOrNull { it.name.startsWith("material-icons-extended") }
        if (icons != null) {
            val named = Regex("androidx/compose/material/icons/[A-Za-z0-9_/]+")
            val used = HashSet<String>()
            for (jar in jars) {
                if (jar == icons) continue
                ZipFile(jar).use { zip ->
                    for (entry in zip.entries()) {
                        if (!entry.name.endsWith(".class")) continue
                        val text = zip.getInputStream(entry).use { it.readBytes() }.toString(Charsets.ISO_8859_1)
                        named.findAll(text).forEach { used += it.value }
                    }
                }
            }
            // What the kept icons name in turn is kept too, until nothing new turns up.
            fun kept(name: String) = name.removeSuffix(".class").substringBefore('$') in used
            ZipFile(icons).use { zip ->
                do {
                    val count = used.size
                    for (entry in zip.entries()) {
                        if (!entry.name.endsWith(".class") || !kept(entry.name)) continue
                        named.findAll(zip.getInputStream(entry).use { it.readBytes() }.toString(Charsets.ISO_8859_1)).forEach { used += it.value }
                    }
                } while (used.size > count)
            }
            rewrite(icons) { name -> !name.endsWith(".class") || kept(name) }
        }
        val after = dir.walkTopDown().filter { it.isFile }.sumOf { it.length() }
        logger.lifecycle("The app folder went from ${before / 1_048_576} MB to ${after / 1_048_576} MB.")
    }
}

// The Windows installer, made by Inno Setup 7 from the release folder with its compiler taken from the iscc property or from where Inno Setup installs itself, and written to build/installer.
val packageReleaseSetup = tasks.register<Exec>("packageReleaseSetup") {
    group = "compose desktop"
    dependsOn(shrinkReleaseImage)
    val installer = layout.projectDirectory.dir("installer")
    val image = layout.buildDirectory.dir("compose/binaries/main-release/app/Sumizuri")
    val output = layout.buildDirectory.dir("installer")
    val version = providers.gradleProperty("app.version")
    val chosen = providers.gradleProperty("iscc")
    // Where Inno Setup 7 puts its compiler, for the person or for everyone.
    val places = listOfNotNull(System.getenv("LOCALAPPDATA")?.let { "$it\\Programs\\Inno Setup 7\\ISCC.exe" }, "C:\\Program Files\\Inno Setup 7\\ISCC.exe", "C:\\Program Files (x86)\\Inno Setup 7\\ISCC.exe")
    inputs.dir(installer)
    inputs.dir(image)
    inputs.property("version", version)
    outputs.dir(output)
    onlyIf { System.getProperty("os.name").lowercase().contains("win") }
    workingDir(installer)
    argumentProviders.add(CommandLineArgumentProvider {
        listOf("/Q", "/DAppVersion=${version.get()}", "/DAppImage=${image.get().asFile.absolutePath}", "/DOutputDir=${output.get().asFile.absolutePath}", "sumizuri.iss")
    })
    doFirst {
        val iscc = chosen.orNull ?: places.firstOrNull { File(it).isFile }
            ?: throw GradleException("Inno Setup 7 is needed to make the installer. Install it, for example with: winget install JRSoftware.InnoSetup, or give its ISCC.exe with -Piscc=path.")
        (this as Exec).executable = iscc
    }
}

// The plain run and the hot reload run are both Java launches, so the browser options go on every one of them.
tasks.withType<JavaExec>().configureEach {
    jvmArgs("--add-opens", "java.desktop/sun.awt=ALL-UNNAMED", "--add-opens", "java.desktop/java.awt.peer=ALL-UNNAMED")
    if (System.getProperty("os.name").lowercase().contains("mac")) {
        jvmArgs("--add-opens", "java.desktop/sun.lwawt=ALL-UNNAMED", "--add-opens", "java.desktop/sun.lwawt.macosx=ALL-UNNAMED")
    }
    // A run is not an installed app, so it finds libmpv and wireproxy in the folder the build puts them in.
    dependsOn(fetchLibmpv, fetchWireproxy)
    systemProperty("sumizuri.mpv.dir", mpvRoot.get().dir("windows").asFile.absolutePath)
    // Marks the run as the debug build, so its window shows Debug and a red icon.
    systemProperty("sumizuri.debug", "true")
}
