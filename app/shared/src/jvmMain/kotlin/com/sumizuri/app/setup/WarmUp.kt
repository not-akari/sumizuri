package com.sumizuri.app.setup

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.ui.ImageComposeScene
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.theme.SumizuriTheme
import com.sumizuri.app.ui.theme.ThemeMode
import com.sumizuri.app.ui.theme.spec.ThemePresets
import java.io.File
import java.util.zip.ZipFile
import kotlin.system.exitProcess

// Libraries a start never reaches, which would only make the archive bigger: the extra icons, the crypto of the SSH tunnel, the browser and its drawing, and helpers only some sources use.
private val Skipped = listOf(
    "material-icons-extended",
    "bcprov",
    "jcef",
    "jogl",
    "gluegen",
    "kcef",
    "commons-",
    "jsch",
    "antlr",
)

// A hidden run that loads the classes of the app with no window and ends, so Java can list them for the archive of classes.
fun warmUp(): Nothing {
    runCatching { drawOnce() }
    runCatching { loadClasses() }
    exitProcess(0)
}

// Draws a small page off the screen, which loads Skia, the text and the parts of Compose every page uses.
private fun drawOnce() {
    val scene = ImageComposeScene(480, 640) {
        SumizuriTheme(ThemeMode.Dark, ThemePresets.first()) {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Text("Sumizuri", style = MaterialTheme.typography.headlineSmall)
                Card { Text("Library", Modifier.padding(12.dp)) }
                Button(onClick = {}) { Text("Continue") }
                Switch(checked = true, onCheckedChange = null)
                LazyColumn { items(20) { Text("Chapter $it") } }
            }
        }
    }
    try {
        scene.render()
        scene.render(16_000_000L)
    } finally {
        scene.close()
    }
}

// Loads every class of the libraries a start uses, without running any of it, so every page is in the archive and not only the ones a first run opened.
private fun loadClasses() {
    val loader = Thread.currentThread().contextClassLoader ?: ClassLoader.getSystemClassLoader()
    val jars = System
        .getProperty("java.class.path")
        .orEmpty()
        .split(File.pathSeparator)
        .map(::File)
    for (jar in jars) {
        if (!jar.isFile || Skipped.any { jar.name.startsWith(it) }) continue
        runCatching {
            ZipFile(jar).use { zip ->
                for (entry in zip.entries()) {
                    val name = entry.name
                    if (!name.endsWith(".class") || name.startsWith("META-INF/") ||
                        name.endsWith("module-info.class")
                    ) {
                        continue
                    }
                    runCatching { Class.forName(name.removeSuffix(".class").replace('/', '.'), false, loader) }
                }
            }
        }
    }
}
