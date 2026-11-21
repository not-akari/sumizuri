package com.sumizuri.app.feature.appupdate

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.NewReleases
import androidx.compose.material.icons.outlined.SystemUpdate
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.BuildInfo
import com.sumizuri.app.data.appupdate.AppRelease
import com.sumizuri.app.data.appupdate.UpdateDownload
import com.sumizuri.app.data.appupdate.UpdatePrefs
import com.sumizuri.app.data.appupdate.UpdateSource
import com.sumizuri.app.data.appupdate.UpdateState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.appupdate_cancel_download
import com.sumizuri.app.shared.resources.appupdate_check_now
import com.sumizuri.app.shared.resources.appupdate_checking
import com.sumizuri.app.shared.resources.appupdate_download
import com.sumizuri.app.shared.resources.appupdate_download_failed
import com.sumizuri.app.shared.resources.appupdate_failed
import com.sumizuri.app.shared.resources.appupdate_install
import com.sumizuri.app.shared.resources.appupdate_last_checked
import com.sumizuri.app.shared.resources.appupdate_limited
import com.sumizuri.app.shared.resources.appupdate_new_version
import com.sumizuri.app.shared.resources.appupdate_no_file
import com.sumizuri.app.shared.resources.appupdate_no_notes
import com.sumizuri.app.shared.resources.appupdate_no_source
import com.sumizuri.app.shared.resources.appupdate_not_found
import com.sumizuri.app.shared.resources.appupdate_opening
import com.sumizuri.app.shared.resources.appupdate_source
import com.sumizuri.app.shared.resources.appupdate_source_hint
import com.sumizuri.app.shared.resources.appupdate_source_invalid
import com.sumizuri.app.shared.resources.appupdate_test_version
import com.sumizuri.app.shared.resources.appupdate_up_to_date
import com.sumizuri.app.shared.resources.appupdate_version_now
import com.sumizuri.app.shared.resources.cancel
import com.sumizuri.app.shared.resources.save
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.art.InkLinearProgressIndicator
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.kit.text.MarkdownText
import com.sumizuri.app.ui.text.agoText
import com.sumizuri.app.ui.text.byteSizeText
import kotlinx.coroutines.flow.first
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// This version, what the last check found and when, and the button that checks again.
@Composable
internal fun StatusCard(state: UpdateState, prefs: UpdatePrefs, onCheck: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    val failed = state is UpdateState.Failed
    val (icon: ImageVector, line: String, tint) = when (state) {
        is UpdateState.Available -> Triple(
            Icons.Outlined.NewReleases,
            stringResource(Res.string.appupdate_new_version, state.latest.version),
            colors.primary,
        )

        is UpdateState.UpToDate -> Triple(
            Icons.Outlined.CheckCircle,
            stringResource(Res.string.appupdate_up_to_date),
            colors.primary,
        )

        is UpdateState.Failed -> Triple(Icons.Outlined.ErrorOutline, stringResource(failureText(state)), colors.error)

        UpdateState.NoSource -> Triple(
            Icons.Outlined.SystemUpdate,
            stringResource(Res.string.appupdate_no_source),
            colors.onSurfaceVariant,
        )

        UpdateState.Checking, UpdateState.Idle -> Triple(
            Icons.Outlined.SystemUpdate,
            stringResource(Res.string.appupdate_checking),
            colors.onSurfaceVariant,
        )
    }
    AppCard(Modifier.fillMaxWidth()) {
        Row(
            Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Box(
                Modifier
                    .size(
                        48.dp,
                    ).background(
                        if (failed) colors.errorContainer else colors.primaryContainer,
                        MaterialTheme.shapes.large,
                    ),
                contentAlignment = Alignment.Center,
            ) {
                if (state is UpdateState.Checking) {
                    InkCircularProgressIndicator(
                        Modifier.size(24.dp),
                        strokeWidth = 2.5.dp,
                        color = colors.onPrimaryContainer,
                    )
                } else {
                    Icon(
                        icon,
                        null,
                        Modifier.size(26.dp),
                        tint = if (failed) colors.onErrorContainer else colors.onPrimaryContainer,
                    )
                }
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(
                    stringResource(Res.string.appupdate_version_now, BuildInfo.Version),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                )
                Text(line, style = MaterialTheme.typography.bodyMedium, color = tint)
                if (prefs.lastCheck >
                    0
                ) {
                    Text(
                        stringResource(Res.string.appupdate_last_checked, agoText(prefs.lastCheck)),
                        style = MaterialTheme.typography.bodySmall,
                        color = colors.outline,
                    )
                }
            }
            InkOutlinedButton(onCheck, enabled = state !is UpdateState.Checking && state !is UpdateState.NoSource) {
                Text(stringResource(Res.string.appupdate_check_now))
            }
        }
    }
}

internal fun failureText(state: UpdateState.Failed): StringResource = when {
    state.notFound -> Res.string.appupdate_not_found
    state.limited -> Res.string.appupdate_limited
    else -> Res.string.appupdate_failed
}

// Saving the newest version and installing it: a button, then how far the download got, then the button that installs it.
@Composable
internal fun DownloadPart(
    hasFile: Boolean,
    download: UpdateDownload?,
    note: StringResource?,
    onDownload: () -> Unit,
    onCancel: () -> Unit,
    onInstall: () -> Unit,
    // While the setup opens the button waits, so it is not opened twice.
    opening: Boolean = false,
) {
    Column(Modifier.fillMaxWidth().padding(vertical = 8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        when {
            !hasFile -> Text(
                stringResource(Res.string.appupdate_no_file),
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.outline,
            )

            download == null -> InkButton(onDownload, Modifier.fillMaxWidth()) {
                Text(stringResource(Res.string.appupdate_download))
            }

            download.error != null -> {
                Text(
                    stringResource(Res.string.appupdate_download_failed),
                    style = MaterialTheme.typography.bodyMedium,
                    color = MaterialTheme.colorScheme.error,
                )
                InkButton(onDownload, Modifier.fillMaxWidth()) { Text(stringResource(Res.string.appupdate_download)) }
            }

            download.finished -> InkButton(onInstall, Modifier.fillMaxWidth(), enabled = !opening) {
                Text(stringResource(if (opening) Res.string.appupdate_opening else Res.string.appupdate_install))
            }

            else -> {
                val total = download.total
                if (total != null && total > 0) {
                    InkLinearProgressIndicator(progress = {
                        (download.done.toFloat() / total).coerceIn(0f, 1f)
                    }, modifier = Modifier.fillMaxWidth().height(6.dp))
                } else {
                    InkLinearProgressIndicator(Modifier.fillMaxWidth().height(6.dp))
                }
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        byteSizeText(download.done) + (total?.let { " / " + byteSizeText(it) } ?: ""),
                        Modifier.weight(1f),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.outline,
                    )
                    TextButton(onCancel) { Text(stringResource(Res.string.appupdate_cancel_download)) }
                }
            }
        }
        if (download !=
            null
        ) {
            Text(
                download.asset.name + (
                    download.asset.size?.let {
                        " · " + byteSizeText(it)
                    } ?: ""
                    ),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.outline,
            )
        }
        note?.let {
            Text(
                stringResource(it),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.error,
            )
        }
    }
}

// One version with when it came out and its notes. A tap on the name shows or hides the notes, and only the first version starts open, so a long list stays short.
@Composable
internal fun ReleaseNotes(release: AppRelease, startOpen: Boolean = true) {
    var open by rememberSaveable(release.version) { mutableStateOf(startOpen) }
    val turn by animateFloatAsState(if (open) 180f else 0f, label = "notes")
    Column(Modifier.fillMaxWidth().padding(vertical = 4.dp)) {
        Row(
            Modifier
                .fillMaxWidth()
                .clickable {
                    open = !open
                }.padding(
                    vertical = 8.dp,
                ),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Row(
                Modifier.weight(1f),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                Text(
                    release.name,
                    Modifier.weight(1f, fill = false),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                )
                if (release.prerelease) {
                    Text(
                        stringResource(Res.string.appupdate_test_version),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.tertiary,
                    )
                }
                release.publishedAt?.let {
                    Text(
                        agoText(it),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.outline,
                    )
                }
            }
            Icon(
                Icons.Outlined.ExpandMore,
                null,
                Modifier.size(20.dp).rotate(turn),
                tint = MaterialTheme.colorScheme.outline,
            )
        }
        AnimatedVisibility(open, enter = expandVertically() + fadeIn(), exit = shrinkVertically() + fadeOut()) {
            Box(Modifier.padding(bottom = 10.dp)) {
                if (release.notes.isBlank()) {
                    Text(
                        stringResource(Res.string.appupdate_no_notes),
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.outline,
                    )
                } else {
                    MarkdownText(release.notes)
                }
            }
        }
    }
}

// The address of the repo to check. Empty goes back to the one the app was built with.
@Composable
internal fun SourceDialog(current: String, onDismiss: () -> Unit, onSave: (String) -> Unit) {
    var text by remember { mutableStateOf(current) }
    val valid = text.isBlank() || UpdateSource.of(text) != null
    AppDialog(
        onDismissRequest = onDismiss,
        title = { Text(stringResource(Res.string.appupdate_source)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    stringResource(Res.string.appupdate_source_hint),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.outline,
                )
                AppTextField(text, {
                    text = it
                }, singleLine = true, isError = !valid, placeholder = { Text("https://github.com/owner/repo") })
                if (!valid) {
                    Text(
                        stringResource(Res.string.appupdate_source_invalid),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.error,
                    )
                }
            }
        },
        confirmButton = {
            InkButton(
                { if (valid) onSave(text) },
                enabled = valid,
            ) { Text(stringResource(Res.string.save)) }
        },
        dismissButton = { InkOutlinedButton(onDismiss) { Text(stringResource(Res.string.cancel)) } },
    )
}
