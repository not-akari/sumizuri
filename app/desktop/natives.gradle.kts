import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream

// The names libraries give this system and processor in the paths of their native files, such as linux_x64, win32-x86-64 or darwin-aarch64. A Mac also keeps the universal ones, which hold both of its processors.
fun ownNatives(): List<String> {
    val system = System.getProperty("os.name").lowercase()
    val arm = System.getProperty("os.arch").lowercase() in setOf("aarch64", "arm64")
    val processors = if (arm) listOf("arm64", "aarch64") else listOf("x64", "x86-64", "x86_64", "amd64")
    val systems = when {
        "win" in system -> listOf("windows", "win32")
        "mac" in system -> listOf("macos", "macosx", "osx", "darwin")
        else -> listOf("linux")
    }
    val universal = if ("mac" in system) listOf("macosx-universal") else emptyList()
    return systems.flatMap { name -> processors.flatMap { listOf("$name-$it", "${name}_$it") } } + universal
}

// The release keeps only the native files of the system and processor it is built on, which is the only one the package runs on. The jars hold them for every system, from 32 bit Windows to BSD and Solaris, and that was about 20 MB of each package.
tasks.matching { it.name == "proguardReleaseJars" }.configureEach {
    // Worked out here, as the step itself may only hold plain values to be kept between builds.
    val own = ownNatives()
    doLast {
        val native = Regex("\\.(so|dylib|jnilib|dll)$")
        val system = Regex("win|linux|darwin|mac|osx|bsd|sunos|aix", RegexOption.IGNORE_CASE)
        fun foreign(path: String) =
            native.containsMatchIn(path) && system.containsMatchIn(path) && own.none { it in path.lowercase() }
        val dir = outputs.files.files.first { it.isDirectory }
        val jars = dir.walkTopDown().filter { it.isFile && it.name.endsWith(".jar") }.toList()
        val before = jars.sumOf { it.length() }
        for (jar in jars) {
            // A jar that only holds the files of another system goes whole.
            if ("natives-" in jar.name && own.none { it in jar.name.lowercase() }) {
                jar.delete()
                continue
            }
            val has = ZipFile(jar).use { zip -> zip.entries().asSequence().any { foreign(it.name) } }
            if (!has) continue
            val kept = File(jar.path + ".tmp")
            ZipFile(jar).use { zip ->
                ZipOutputStream(kept.outputStream().buffered()).use { out ->
                    for (entry in zip.entries()) {
                        if (foreign(entry.name)) continue
                        // Stored entries stay stored, as the app reads its texts from them unpacked.
                        out.putNextEntry(ZipEntry(entry).apply { if (method == ZipEntry.DEFLATED) compressedSize = -1 })
                        zip.getInputStream(entry).use { it.copyTo(out) }
                        out.closeEntry()
                    }
                }
            }
            jar.delete()
            kept.renameTo(jar)
        }
        val after = dir.walkTopDown().filter { it.isFile && it.name.endsWith(".jar") }.sumOf { it.length() }
        logger.lifecycle(
            "The native files of other systems left the jars, from ${before / 1_048_576} MB to ${after / 1_048_576} MB.",
        )
    }
}
