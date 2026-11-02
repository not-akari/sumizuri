package com.sumizuri.app.feature.appupdate

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.SystemUpdate
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.BuildInfo
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.appupdate.AppRelease
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.appupdate_all_versions
import com.sumizuri.app.shared.resources.appupdate_notice_body
import com.sumizuri.app.shared.resources.appupdate_notice_close
import com.sumizuri.app.shared.resources.appupdate_notice_title
import com.sumizuri.app.shared.resources.appupdate_notice_view
import com.sumizuri.app.shared.resources.appupdate_whats_new
import com.sumizuri.app.shared.resources.ok
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkLinearProgressIndicator
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.text.MarkdownText
import kotlinx.coroutines.delay
import org.jetbrains.compose.resources.stringResource

// How long the app waits after it opens before it looks for a new version, so the first screen loads first.
private const val QuietMs = 4_000L

// How long the notice of a new version stays before it goes away on its own.
private const val ShowMs = 5_000

// What the app says about its own versions when it opens: a notice at the top when a new version is out, which goes away after five seconds, and the notes of this version once after it was updated. onOpen opens the page of updates.
@Composable
fun AppUpdateNotices(onOpen: () -> Unit, modifier: Modifier = Modifier) {
    val updater = LocalAppContainer.current.updater
    var notice by remember { mutableStateOf<AppRelease?>(null) }
    var visible by remember { mutableStateOf(false) }
    var news by remember { mutableStateOf<AppRelease?>(null) }
    LaunchedEffect(updater) {
        news = updater.whatsNew()
        delay(QuietMs)
        updater.checkIfDue()?.let {
            notice = it
            visible = true
        }
    }
    // The bar under the notice empties as the five seconds run out.
    val left = remember { Animatable(1f) }
    LaunchedEffect(notice) {
        if (notice == null) return@LaunchedEffect
        left.snapTo(1f)
        left.animateTo(0f, tween(ShowMs, easing = LinearEasing))
        visible = false
    }
    AnimatedVisibility(
        visible,
        modifier,
        enter = slideInVertically { -it } + fadeIn(),
        exit =
        slideOutVertically { -it } + fadeOut(),
    ) {
        notice?.let { release ->
            NoticeCard(release, { left.value }, onOpen = {
                visible = false
                onOpen()
            }, onClose = { visible = false })
        }
    }
    news?.let { release ->
        WhatsNewDialog(release, onDismiss = { news = null }, onAll = {
            news = null
            onOpen()
        })
    }
}

@Composable
private fun NoticeCard(release: AppRelease, left: () -> Float, onOpen: () -> Unit, onClose: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    Surface(
        onOpen,
        Modifier.widthIn(max = 520.dp).fillMaxWidth(),
        shape = MaterialTheme.shapes.large,
        color = colors.surfaceContainerHighest,
        shadowElevation = 6.dp,
        tonalElevation = 2.dp,
    ) {
        Column {
            Row(
                Modifier.padding(start = 14.dp, top = 12.dp, bottom = 10.dp, end = 4.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Box(
                    Modifier.size(40.dp).background(colors.primaryContainer, CircleShape),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Outlined.SystemUpdate, null, Modifier.size(22.dp), tint = colors.onPrimaryContainer)
                }
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(
                        stringResource(Res.string.appupdate_notice_title, release.version),
                        style = MaterialTheme.typography.titleSmall,
                        fontWeight = FontWeight.SemiBold,
                        // Two lines, so the version is never cut on a narrow phone.
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                    Text(
                        stringResource(Res.string.appupdate_notice_body, BuildInfo.Version),
                        style = MaterialTheme.typography.bodySmall,
                        color = colors.onSurfaceVariant,
                        maxLines = 2,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
                TextButton(onOpen) { Text(stringResource(Res.string.appupdate_notice_view)) }
                IconButton(onClose) { Icon(Icons.Outlined.Close, stringResource(Res.string.appupdate_notice_close)) }
            }
            InkLinearProgressIndicator(progress = left, modifier = Modifier.fillMaxWidth().height(3.dp))
        }
    }
}

// The notes of the version the app was just updated to.
@Composable
private fun WhatsNewDialog(release: AppRelease, onDismiss: () -> Unit, onAll: () -> Unit) {
    AppDialog(
        onDismissRequest = onDismiss,
        icon = { Icon(Icons.Outlined.SystemUpdate, null) },
        title = { Text(stringResource(Res.string.appupdate_whats_new, release.version)) },
        text = {
            Column(Modifier.heightIn(max = 420.dp).verticalScroll(rememberScrollState())) {
                MarkdownText(release.notes)
            }
        },
        confirmButton = { InkButton(onDismiss) { Text(stringResource(Res.string.ok)) } },
        dismissButton = { InkOutlinedButton(onAll) { Text(stringResource(Res.string.appupdate_all_versions)) } },
    )
}
