// The Windows setup file: the launcher cargo builds from this folder, then the release folder as zstd chunks, the list of the files and a footer, written to build/installer.
import com.github.luben.zstd.Zstd
import java.io.ByteArrayOutputStream
import java.io.RandomAccessFile
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

buildscript {
    repositories { mavenCentral() }
    dependencies { classpath("com.github.luben:zstd-jni:1.5.7-3") }
}

// Writes numbers the way the launcher reads them, low byte first.
class Bytes : ByteArrayOutputStream() {
    fun u8(value: Int) = write(value)

    fun u16(value: Int) = repeat(2) { write(value ushr (8 * it) and 0xFF) }

    fun u32(value: Int) = repeat(4) { write(value ushr (8 * it) and 0xFF) }

    fun u64(value: Long) = repeat(8) { write((value ushr (8 * it)).toInt() and 0xFF) }
}

// How the launcher starts the setup: Java itself, with the jars the setup window needs, from the folder of the app.
object SetupStart {
    // The files the setup window never opens, unpacked behind it once it is open: the video player, the network helper and the browser parts.
    val later = listOf(
        Regex("app/resources/libmpv-2\\.dll"),
        Regex("app/resources/wireproxy\\.exe"),
        Regex("app/(jcef|kcef|jogl|gluegen)[^/]*\\.jar"),
    )

    // Light options for a short run: one small collector, the quick compiler only, and no counters.
    private val options = listOf(
        "-Dcompose.application.resources.dir=app/resources",
        "-Dcompose.application.configure.swing.globals=true",
        "-Dskiko.library.path=app",
        "--add-opens",
        "java.desktop/sun.awt=ALL-UNNAMED",
        "--add-opens",
        "java.desktop/java.awt.peer=ALL-UNNAMED",
        "-Xmx512m",
        "-XX:+UseSerialGC",
        "-XX:TieredStopAtLevel=1",
        "-XX:-UsePerfData",
    )

    // The jars of the app in the order its launcher has them, without the later ones, with paths from the folder of the app.
    fun classPath(root: File): String = File(root, "app/Sumizuri.cfg")
        .readLines()
        .filter { it.startsWith("app.classpath=") }
        .map { "app/" + it.substringAfterLast('\\').substringAfterLast('/') }
        .filter { name -> later.none { it.matches(name) } }
        .joinToString(";")

    fun mainClass(root: File): String = File(root, "app/Sumizuri.cfg")
        .readLines()
        .first { it.startsWith("app.mainclass=") }
        .substringAfter('=')

    // Every argument before the ones the launcher adds, one to a line in the file it reads.
    fun args(root: File): List<String> = options + listOf("-cp", classPath(root), mainClass(root))

    fun java(root: File) = File(root, "runtime/bin/java.exe")
}

// Packs the folder after the launcher, with the start of the setup and its class archive in a group of their own. Each chunk is packed on its own, and kept plain when zstd cannot make it smaller.
abstract class PackSetup : DefaultTask() {
    @get:InputDirectory
    abstract val image: DirectoryProperty

    @get:InputFile
    abstract val launcher: RegularFileProperty

    // The classes the setup loads, recorded by recordSetupClasses. A stale list only means some classes load the slow way.
    @get:InputFile
    @get:Optional
    abstract val classList: RegularFileProperty

    @get:OutputFile
    abstract val output: RegularFileProperty

    private class Piece(val file: Int, val start: Long, val length: Int)

    // Makes the class archive of the setup from the recorded list, or leaves it out when Java could not.
    private fun dumpArchive(root: File, list: File, archive: File) {
        archive.delete()
        val dump = ProcessBuilder(
            SetupStart.java(root).absolutePath,
            "-Xshare:dump",
            "-XX:SharedClassListFile=${list.absolutePath}",
            "-XX:SharedArchiveFile=${archive.absolutePath}",
            "-cp",
            SetupStart.classPath(root),
        ).directory(root).redirectErrorStream(true).start()
        val said = dump.inputStream.bufferedReader().readText()
        if (!dump.waitFor(5, TimeUnit.MINUTES) || dump.exitValue() != 0) {
            logger.warn(
                "The class archive of the setup could not be made, so it starts without one: ${said.takeLast(2000)}",
            )
            archive.delete()
        }
        // Java makes the archive read only, which would stop the next build from replacing it.
        archive.setWritable(true)
    }

    @TaskAction
    fun pack() {
        val started = System.nanoTime()
        val root = image.get().asFile
        val target = output.get().asFile
        val launcherFile = launcher.get().asFile
        val setup = File(temporaryDir, "setup").apply {
            deleteRecursively()
            mkdirs()
        }
        File(setup, "setup.args").writeText(SetupStart.args(root).joinToString("\n"))
        val list = classList.orNull?.asFile
        if (list != null && list.isFile &&
            SetupStart.java(root).isFile
        ) {
            dumpArchive(root, list, File(setup, "setup.jsa"))
        }
        val shipped = root
            .walkTopDown()
            .filter { it.isFile }
            .sortedBy {
                it
                    .relativeTo(
                        root,
                    ).invariantSeparatorsPath
            }.toList()
        val extra = setup.listFiles().orEmpty().sortedBy { it.name }
        val files = shipped + extra
        val names = shipped.map { it.relativeTo(root).invariantSeparatorsPath } + extra.map { it.name }
        val groups =
            shipped.indices.map { if (SetupStart.later.any { re -> re.matches(names[it]) }) 1 else 0 } + extra.map { 2 }
        val pieces = files.flatMapIndexed { index, file ->
            (0 until file.length() step CHUNK.toLong()).map { start ->
                Piece(index, start, minOf(CHUNK.toLong(), file.length() - start).toInt())
            }
        }
        val pool = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors())
        val packed = pieces.map { piece ->
            pool.submit<ByteArray> {
                val raw = ByteArray(piece.length)
                RandomAccessFile(files[piece.file], "r").use {
                    it.seek(piece.start)
                    it.readFully(raw)
                }
                val small = Zstd.compress(raw, LEVEL)
                if (small.size < raw.size) small else raw
            }
        }
        target.parentFile.mkdirs()
        val chunks = Array(files.size) { mutableListOf<Triple<Long, Int, Int>>() }
        target.outputStream().buffered(1 shl 20).use { out ->
            launcherFile.inputStream().use { it.copyTo(out) }
            var offset = launcherFile.length()
            pieces.forEachIndexed { index, piece ->
                val data = packed[index].get()
                out.write(data)
                chunks[piece.file] += Triple(offset, data.size, piece.length)
                offset += data.size
            }
            pool.shutdown()
            val index = Bytes()
            index.u32(files.size)
            files.forEachIndexed { at, file ->
                val name = names[at].toByteArray(Charsets.UTF_8)
                index.u8(groups[at])
                index.u16(name.size)
                index.write(name)
                index.u64(file.length())
                // In steps of 100 nanoseconds, as fine as Windows keeps it, since Java compares the exact time.
                index.u64(
                    java.nio.file.Files
                        .getLastModifiedTime(file.toPath())
                        .to(TimeUnit.NANOSECONDS) / 100,
                )
                index.u32(chunks[at].size)
                for ((place, size, raw) in chunks[at]) {
                    index.u64(place)
                    index.u32(size)
                    index.u32(raw)
                }
            }
            out.write(index.toByteArray())
            val footer = Bytes()
            footer.write("SMZSETUP".toByteArray(Charsets.US_ASCII))
            footer.u64(offset)
            footer.u64(index.size().toLong())
            out.write(footer.toByteArray())
        }
        val archive = if (File(setup, "setup.jsa").isFile) "with" else "without"
        logger.lifecycle(
            "Packed ${target.name}, ${target.length() / 1_048_576} MB, $archive a class archive, in ${(System.nanoTime() - started) / 1_000_000_000} s.",
        )
    }

    companion object {
        // Big files are cut into chunks of this size, so every core can unpack a part of them at once.
        const val CHUNK = 4 shl 20
        const val LEVEL = 19
    }
}

// Runs the setup of the release folder for a few seconds and writes down every class it loads, for the class archive. It opens the setup window, so it is run by hand after the setup changes much.
abstract class RecordSetupClasses : DefaultTask() {
    @get:InputDirectory
    abstract val image: DirectoryProperty

    @get:OutputFile
    abstract val output: RegularFileProperty

    @TaskAction
    fun record() {
        val root = image.get().asFile
        val target = output.get().asFile
        target.delete()
        val run = ProcessBuilder(
            listOf(
                SetupStart.java(root).absolutePath,
                "-XX:DumpLoadedClassList=${target.absolutePath}",
                "-Djpackage.app-path=${File(root, "Sumizuri.exe").absolutePath}",
            ) +
                SetupStart.args(root) + "--setup",
        ).directory(root).redirectErrorStream(true).redirectOutput(ProcessBuilder.Redirect.DISCARD).start()
        run.waitFor(10, TimeUnit.SECONDS)
        run.descendants().forEach { it.destroyForcibly() }
        run.destroyForcibly().waitFor()
        logger.lifecycle("Recorded ${target.readLines().count { !it.startsWith("#") }} classes in ${target.name}.")
    }
}

val launcherDir = layout.projectDirectory.dir("launcher")
val releaseImage = layout.buildDirectory.dir("compose/binaries/main-release/app/Sumizuri")

// Cargo from the cargo property, from where rustup puts it, or from the path.
val buildSetupLauncher = tasks.register<Exec>("buildSetupLauncher") {
    group = "compose desktop"
    val version = providers.gradleProperty("app.version")
    val chosen = providers.gradleProperty("cargo")
    val home = File(System.getProperty("user.home"), ".cargo/bin/cargo.exe")
    inputs.dir(launcherDir.dir("src"))
    inputs.files(
        launcherDir.file("Cargo.toml"),
        launcherDir.file("Cargo.lock"),
        launcherDir.file("build.rs"),
        launcherDir.file("setup.rc"),
        launcherDir.file("splash-logo.png"),
        layout.projectDirectory.file("icons/app-icon.ico"),
    )
    inputs.property("version", version)
    outputs.file(launcherDir.file("target/release/sumizuri-setup.exe"))
    onlyIf { System.getProperty("os.name").lowercase().contains("win") }
    workingDir(launcherDir)
    environment("SUMIZURI_VERSION", version.get())
    executable(chosen.orNull ?: if (home.isFile) home.absolutePath else "cargo")
    args("build", "--release", "--locked")
}

tasks.register<PackSetup>("packageReleaseSetup") {
    group = "compose desktop"
    // A test can pack another folder with the setupImage property, which skips the release build.
    val chosenImage = providers.gradleProperty("setupImage")
    dependsOn(buildSetupLauncher)
    if (!chosenImage.isPresent) dependsOn("shrinkReleaseImage")
    image.fileProvider(chosenImage.map { File(it) }.orElse(releaseImage.map { it.asFile }))
    launcher.set(launcherDir.file("target/release/sumizuri-setup.exe"))
    classList.set(launcherDir.file("setup.classlist"))
    output.set(
        layout.buildDirectory.file(
            providers.gradleProperty("app.version").map {
                "installer/Sumizuri-$it-setup.exe"
            },
        ),
    )
    onlyIf { System.getProperty("os.name").lowercase().contains("win") }
}

tasks.register<RecordSetupClasses>("recordSetupClasses") {
    group = "compose desktop"
    dependsOn("shrinkReleaseImage")
    image.set(releaseImage)
    output.set(launcherDir.file("setup.classlist"))
    onlyIf { System.getProperty("os.name").lowercase().contains("win") }
}
