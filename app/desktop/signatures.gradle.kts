import java.util.jar.Manifest
import java.util.zip.ZipEntry
import java.util.zip.ZipFile
import java.util.zip.ZipOutputStream

// A signed library carries its signature and a checksum of every file in its manifest, which Java reads in full at the start that makes the archive of classes. For BouncyCastle that took over seven seconds, and nothing in the app checks signatures, so both are left out.
abstract class LeaveOutSignature : TransformAction<TransformParameters.None> {
    @get:InputArtifact
    abstract val input: Provider<FileSystemLocation>

    override fun transform(outputs: TransformOutputs) {
        val jar = input.get().asFile
        val signature = Regex("^META-INF/[^/]+\\.(SF|RSA|DSA|EC)$", RegexOption.IGNORE_CASE)
        val signed =
            jar.isFile && ZipFile(jar).use { zip -> zip.entries().asSequence().any { signature.matches(it.name) } }
        if (!signed) {
            outputs.file(input)
            return
        }
        val out = outputs.file(jar.name)
        ZipFile(jar).use { zip ->
            ZipOutputStream(out.outputStream().buffered()).use { stream ->
                for (entry in zip.entries()) {
                    if (signature.matches(entry.name)) continue
                    // BouncyCastle offers itself as a security provider of Java, which the app never uses, and the shrinking of the release would leave that offer pointing at nothing.
                    if (entry.name == "META-INF/services/java.security.Provider") continue
                    stream.putNextEntry(ZipEntry(entry.name).apply { time = entry.time })
                    if (entry.name == "META-INF/MANIFEST.MF") {
                        val manifest = zip.getInputStream(entry).use { Manifest(it) }
                        manifest.entries.clear()
                        manifest.write(stream)
                    } else {
                        zip.getInputStream(entry).use { it.copyTo(stream) }
                    }
                    stream.closeEntry()
                }
            }
        }
    }
}

// Every jar the app runs with passes through the step above, which only changes the signed ones.
val unsigned = Attribute.of("sumizuri.unsigned", Boolean::class.javaObjectType)
dependencies {
    attributesSchema { attribute(unsigned) }
    artifactTypes.maybeCreate("jar").attributes.attribute(unsigned, false)
    registerTransform(LeaveOutSignature::class) {
        from.attribute(unsigned, false).attribute(ArtifactTypeDefinition.ARTIFACT_TYPE_ATTRIBUTE, "jar")
        to.attribute(unsigned, true).attribute(ArtifactTypeDefinition.ARTIFACT_TYPE_ATTRIBUTE, "jar")
    }
}
configurations.named("runtimeClasspath") { attributes.attribute(unsigned, true) }
