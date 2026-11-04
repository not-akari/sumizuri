package com.sumizuri.app.data

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Canvas
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.graphics.asAndroidBitmap
import androidx.compose.ui.graphics.drawscope.CanvasDrawScope
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.LayoutDirection
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import com.sumizuri.app.AndroidApp
import com.sumizuri.app.ui.kit.art.drawIconArt

// How big the picture of a pinned shortcut is drawn, which is the full grid of an adaptive icon.
private const val PinSize = 432

// The id of the shortcut with the icon a person made, so pinning again or changing the icon updates the one shortcut.
private const val PinId = "own-icon"

// Each built-in icon is an entry of the launcher that opens the app, and the one picked is the only one on, as Android cannot draw a launcher icon of its own. Only the usual one is on in the manifest. The exact icon a person made can go on the home screen as a shortcut.
actual object AppIcons {
    actual val supported: Boolean = true

    actual val launcher: Boolean = true

    actual val canPin: Boolean get() = ShortcutManagerCompat.isRequestPinShortcutSupported(AndroidApp.context)

    private val store by lazy { AndroidApp.context.getSharedPreferences("app_icon", Context.MODE_PRIVATE) }

    private fun entry(icon: AppIcon) = ComponentName(AndroidApp.context, "com.sumizuri.app.${icon.launcherName}")

    private fun isOn(icon: AppIcon): Boolean =
        when (AndroidApp.context.packageManager.getComponentEnabledSetting(entry(icon))) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> icon == AppIcon.Usual
            else -> false
        }

    actual fun current(): AppIcon = AppIcon.all.firstOrNull { it != AppIcon.Usual && isOn(it) } ?: AppIcon.Usual

    // The new entry is turned on before the old ones go, so the app is never without one. An entry already on is left as it is.
    actual fun choose(icon: AppIcon) {
        val manager = AndroidApp.context.packageManager
        val on = AppIcon.all.filter { isOn(it) }
        if (on == listOf(icon)) return
        manager.setComponentEnabledSetting(
            entry(icon),
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
            PackageManager.DONT_KILL_APP,
        )
        for (other in on - icon) {
            manager.setComponentEnabledSetting(
                entry(other),
                PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                PackageManager.DONT_KILL_APP,
            )
        }
    }

    actual fun loadDesign(): String? = store.getString("design", null)

    actual fun saveDesign(text: String) {
        store.edit().putString("design", text).apply()
    }

    actual fun pin(design: IconDesign, label: String): Boolean {
        val context = AndroidApp.context
        return runCatching {
            ShortcutManagerCompat.requestPinShortcut(context, shortcut(design, label), null)
        }.getOrDefault(false)
    }

    actual fun refreshPin(design: IconDesign) {
        val context = AndroidApp.context
        runCatching {
            val pinned =
                ShortcutManagerCompat.getShortcuts(context, ShortcutManagerCompat.FLAG_MATCH_PINNED).firstOrNull {
                    it.id ==
                        PinId
                }
                    ?: return
            ShortcutManagerCompat.updateShortcuts(context, listOf(shortcut(design, pinned.shortLabel.toString())))
        }
    }

    private fun shortcut(design: IconDesign, label: String): ShortcutInfoCompat {
        val context = AndroidApp.context
        val open = Intent(Intent.ACTION_MAIN)
            .setClassName(context, "com.sumizuri.app.MainActivity")
            .addCategory(Intent.CATEGORY_LAUNCHER)
        return ShortcutInfoCompat
            .Builder(context, PinId)
            .setShortLabel(label)
            .setIcon(IconCompat.createWithAdaptiveBitmap(picture(design)))
            .setIntent(open)
            .build()
    }

    // The icon on the full grid of an adaptive icon, its background filling it, for the home screen to cut to its own shape.
    private fun picture(design: IconDesign): android.graphics.Bitmap {
        val image = ImageBitmap(PinSize, PinSize)
        CanvasDrawScope().draw(
            Density(1f),
            LayoutDirection.Ltr,
            Canvas(image),
            Size(PinSize.toFloat(), PinSize.toFloat()),
        ) {
            drawRect(Color(design.color(IconPart.Back)))
            drawIconArt(design, onGrid = true)
        }
        return image.asAndroidBitmap()
    }
}
