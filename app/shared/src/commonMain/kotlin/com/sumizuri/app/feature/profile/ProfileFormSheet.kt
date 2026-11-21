package com.sumizuri.app.feature.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.profile.Profile
import com.sumizuri.app.data.text.monthYearText
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.profile_change_photo
import com.sumizuri.app.shared.resources.profile_create
import com.sumizuri.app.shared.resources.profile_create_failed
import com.sumizuri.app.shared.resources.profile_created_on
import com.sumizuri.app.shared.resources.profile_delete
import com.sumizuri.app.shared.resources.profile_delete_message
import com.sumizuri.app.shared.resources.profile_delete_switch_first
import com.sumizuri.app.shared.resources.profile_delete_title
import com.sumizuri.app.shared.resources.profile_deleting
import com.sumizuri.app.shared.resources.profile_edit
import com.sumizuri.app.shared.resources.profile_name
import com.sumizuri.app.shared.resources.profile_name_hint
import com.sumizuri.app.shared.resources.profile_new
import com.sumizuri.app.shared.resources.profile_new_hint
import com.sumizuri.app.shared.resources.profile_photo_failed
import com.sumizuri.app.shared.resources.profile_remove_photo
import com.sumizuri.app.shared.resources.profile_save
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.card.AppListRow
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.dialog.CancelButton
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.kit.input.rememberImagePicker
import com.sumizuri.app.ui.kit.input.squareAvatar
import com.sumizuri.app.ui.kit.page.PageGutter
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.decodeToImageBitmap
import org.jetbrains.compose.resources.stringResource

private const val LongestName = 40
private const val PictureSize = 512

// Making a profile and editing one are the same form: a picture to tap, a name and one button. The profile that is open is not deleted from under the app, so that waits until another one is open.
@OptIn(ExperimentalMaterial3Api::class)
@Composable
internal fun ProfileFormSheet(profile: Profile?, isActive: Boolean, calls: ProfileCalls, onDismiss: () -> Unit) {
    var name by remember { mutableStateOf(profile?.name.orEmpty()) }
    var picked by remember { mutableStateOf<ByteArray?>(null) }
    var removed by remember { mutableStateOf(false) }
    var busy by remember { mutableStateOf(false) }
    var deleting by remember { mutableStateOf(false) }
    var confirming by remember { mutableStateOf(false) }
    var problem by remember { mutableStateOf<StringResource?>(null) }
    val scope = rememberCoroutineScope()
    val chosen = remember(picked) { picked?.decodeToImageBitmap() }
    val pick = rememberImagePicker { bytes ->
        scope.launch {
            val square = withContext(Dispatchers.Default) { squareAvatar(bytes, PictureSize) }
            if (square == null) {
                problem = Res.string.profile_photo_failed
            } else {
                problem = null
                picked = square
                removed = false
            }
        }
    }
    val shownAvatar = if (removed) null else profile?.avatar

    ModalBottomSheet(
        modifier = Modifier.windowInsetsPadding(
            WindowInsets.statusBars.only(WindowInsetsSides.Top),
        ),
        shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
        containerColor = MaterialTheme.colorScheme.surfaceContainerHigh,
        onDismissRequest = {
            if (!deleting) onDismiss()
        },
    ) {
        if (deleting) {
            Column(
                Modifier.fillMaxWidth().padding(horizontal = PageGutter, vertical = 36.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(20.dp),
            ) {
                InkCircularProgressIndicator()
                Text(
                    stringResource(Res.string.profile_deleting),
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    textAlign = TextAlign.Center,
                )
            }
            return@ModalBottomSheet
        }
        Column(
            Modifier.verticalScroll(rememberScrollState()).padding(horizontal = PageGutter).padding(bottom = 24.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Text(
                stringResource(
                    if (profile ==
                        null
                    ) {
                        Res.string.profile_new
                    } else {
                        Res.string.profile_edit
                    },
                ),
                style = MaterialTheme.typography.titleLarge,
                modifier = Modifier.fillMaxWidth(),
            )
            if (profile ==
                null
            ) {
                Text(
                    stringResource(Res.string.profile_new_hint),
                    Modifier.fillMaxWidth(),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.outline,
                )
            }
            Box(Modifier.clickable(enabled = !busy, onClick = pick)) {
                ProfileAvatar(
                    name.ifBlank {
                        "P"
                    },
                    shownAvatar,
                    96.dp,
                    Modifier
                        .border(
                            2.dp,
                            MaterialTheme.colorScheme.primary,
                            CircleShape,
                        ).padding(3.dp)
                        .clip(CircleShape),
                    chosen,
                )
                Box(
                    Modifier
                        .align(Alignment.BottomEnd)
                        .size(32.dp)
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.primary),
                    contentAlignment = Alignment.Center,
                ) {
                    Icon(Icons.Filled.CameraAlt, null, Modifier.size(18.dp), tint = MaterialTheme.colorScheme.onPrimary)
                }
            }
            PhotoButtons(busy, pick, hasPicture = chosen != null || shownAvatar != null) {
                picked = null
                removed = true
            }
            problem?.let {
                Text(
                    stringResource(it),
                    color = MaterialTheme.colorScheme.error,
                    style = MaterialTheme.typography.bodySmall,
                )
            }
            AppTextField(
                name,
                { name = it.take(LongestName) },
                Modifier.fillMaxWidth(),
                singleLine = true,
                enabled = !busy,
                label = { Text(stringResource(Res.string.profile_name)) },
                placeholder = { Text(stringResource(Res.string.profile_name_hint)) },
            )
            if (profile != null) {
                Text(
                    stringResource(Res.string.profile_created_on, monthYearText(profile.createdAt)),
                    Modifier.fillMaxWidth(),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.outline,
                )
            }
            InkButton(
                onClick = {
                    busy = true
                    if (profile == null) {
                        scope.launch {
                            if (calls.onCreate(name, picked)) {
                                onDismiss()
                            } else {
                                busy = false
                                problem = Res.string.profile_create_failed
                            }
                        }
                    } else {
                        calls.onSave(profile.id, name, picked, removed)
                        onDismiss()
                    }
                },
                enabled = !busy && name.isNotBlank(),
                modifier = Modifier.fillMaxWidth(),
            ) { Text(stringResource(if (profile == null) Res.string.profile_create else Res.string.profile_save)) }
            if (profile != null && !isActive) {
                AppListRow(
                    stringResource(Res.string.profile_delete),
                    leading = { Icon(Icons.Outlined.DeleteOutline, null, tint = MaterialTheme.colorScheme.error) },
                    onClick = { confirming = true },
                )
            } else if (profile != null) {
                Text(
                    stringResource(Res.string.profile_delete_switch_first),
                    Modifier.fillMaxWidth(),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.outline,
                    textAlign = TextAlign.Center,
                )
            }
        }
    }
    if (confirming && profile != null) {
        AppDialog(
            onDismissRequest = { confirming = false },
            title = { Text(stringResource(Res.string.profile_delete_title, profile.name)) },
            text = { Text(stringResource(Res.string.profile_delete_message)) },
            confirmButton = {
                InkButton({
                    confirming = false
                    deleting = true
                    scope.launch {
                        calls.onDelete(profile.id)
                        onDismiss()
                    }
                }) { Text(stringResource(Res.string.profile_delete), color = MaterialTheme.colorScheme.error) }
            },
            dismissButton = { CancelButton({ confirming = false }) },
        )
    }
}

// The two buttons under the picture: one to choose another and one to take it away when there is one.
@Composable
private fun PhotoButtons(busy: Boolean, onChange: () -> Unit, hasPicture: Boolean, onRemove: () -> Unit) {
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
        TextButton(onChange, enabled = !busy) { Text(stringResource(Res.string.profile_change_photo)) }
        if (hasPicture) TextButton(onRemove, enabled = !busy) { Text(stringResource(Res.string.profile_remove_photo)) }
    }
}
