package com.sumizuri.app.ui.kit.window

import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.CropSquare
import androidx.compose.material.icons.outlined.FilterNone
import androidx.compose.material.icons.outlined.Remove
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.inset
import androidx.compose.ui.graphics.painter.Painter
import androidx.compose.ui.graphics.vector.rememberVectorPainter
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.core.AppBuild
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.window_close
import com.sumizuri.app.shared.resources.window_maximize
import com.sumizuri.app.shared.resources.window_minimize
import com.sumizuri.app.shared.resources.window_restore
import com.sumizuri.app.ui.kit.art.AppIconArt
import com.sumizuri.app.ui.text.appName
import org.jetbrains.compose.resources.stringResource

// How tall the bar is.
private val BarHeight = 36.dp

// The bar over the top of a desktop window that has no bar from the system: the icon of the app and the name of the app on the left, which can be dragged and a double tap on it maximizes the window without taking the press from the drag, and the buttons to minimize, maximize and close on the right. The drag is given by the window, since only the window knows how to move itself.
@Composable
fun WindowBar(
    maximized: Boolean,
    onMinimize: () -> Unit,
    onToggleMaximize: () -> Unit,
    onClose: () -> Unit,
    drag: @Composable (@Composable () -> Unit) -> Unit,
    modifier: Modifier = Modifier,
) {
    val colors = MaterialTheme.colorScheme
    // Drawn above the app and outside its surface, so it sets the color of its own text and icons.
    Surface(modifier.fillMaxWidth(), color = colors.surfaceContainer, contentColor = colors.onSurface) {
        Column {
            Row(Modifier.fillMaxWidth().height(BarHeight), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.weight(1f).fillMaxHeight()) {
                    drag {
                        Row(
                            Modifier.fillMaxSize().onDoubleTap(onToggleMaximize).padding(start = 12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Image(AppIconArt, null, Modifier.size(20.dp))
                            Text(
                                appName(),
                                Modifier.padding(start = 10.dp),
                                style = MaterialTheme.typography.labelLarge,
                                fontWeight = FontWeight.SemiBold,
                                color = colors.onSurface,
                            )
                        }
                    }
                }
                WindowButton(Icons.Outlined.Remove, stringResource(Res.string.window_minimize), onMinimize)
                WindowButton(
                    if (maximized) Icons.Outlined.FilterNone else Icons.Outlined.CropSquare,
                    stringResource(if (maximized) Res.string.window_restore else Res.string.window_maximize),
                    onToggleMaximize,
                )
                WindowButton(Icons.Outlined.Close, stringResource(Res.string.window_close), onClose, danger = true)
            }
            HorizontalDivider(color = colors.outlineVariant)
        }
    }
}

// The icon of the app, for the window of a desktop. A debug build gets it inside a red frame.
@Composable
fun appIcon(): Painter {
    val icon = rememberVectorPainter(AppIconArt)
    return if (AppBuild.isDebug) remember(icon) { DebugIcon(icon) } else icon
}

private val DebugRed = Color(0xFFC62828)

// The icon drawn smaller on a red rounded square, which still shows at the size of a taskbar.
private class DebugIcon(private val icon: Painter) : Painter() {
    override val intrinsicSize: Size get() = icon.intrinsicSize

    override fun DrawScope.onDraw() {
        drawRoundRect(DebugRed, cornerRadius = CornerRadius(size.minDimension * 0.22f))
        inset(size.minDimension * 0.12f) {
            with(icon) { draw(size) }
        }
    }
}
