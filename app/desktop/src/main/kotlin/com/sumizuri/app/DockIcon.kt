package com.sumizuri.app

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.graphics.toAwtImage
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.LayoutDirection
import com.sumizuri.app.data.AppIconShown
import com.sumizuri.app.data.IconDesign
import com.sumizuri.app.data.appIconsShown
import java.awt.Taskbar

// How big the dock icon is drawn, as big as a Mac shows it.
private const val DockSize = 512f

// A Mac takes the dock icon from the app bundle and not from the window, so a picked icon is drawn and handed to the dock. The usual icon is left to the bundle until another one has been picked.
@Composable
internal fun DockIcon(icon: Painter) {
    var changed by remember { mutableStateOf(false) }
    val picked = appIconsShown && AppIconShown.now() != IconDesign.Usual
    LaunchedEffect(icon, picked) {
        if (!picked && !changed) return@LaunchedEffect
        runCatching {
            val image = icon.toAwtImage(Density(1f), LayoutDirection.Ltr, Size(DockSize, DockSize))
            Taskbar.getTaskbar().iconImage = image
            changed = true
        }
    }
}
