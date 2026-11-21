package com.sumizuri.app.feature.title.edit

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandHorizontally
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkHorizontally
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.ImageSearch
import androidx.compose.material.icons.outlined.Restore
import androidx.compose.material.icons.outlined.UploadFile
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.edit_cover_file
import com.sumizuri.app.shared.resources.edit_cover_source
import com.sumizuri.app.shared.resources.edit_cover_sources
import com.sumizuri.app.shared.resources.edit_edited
import com.sumizuri.app.shared.resources.edit_genre_hint
import com.sumizuri.app.shared.resources.edit_use_source
import com.sumizuri.app.shared.resources.remove
import com.sumizuri.app.ui.kit.card.CardButton
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.input.SoftField
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// One part of the title to edit: its name in small capitals, and once it differs from the source a mark that says so with a way to give the source its say again.
@Composable
internal fun FieldBlock(label: String, edited: Boolean, onUseSource: () -> Unit, content: @Composable () -> Unit) {
    val ms = motionMs(AppMotion.Medium)
    Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
        Row(Modifier.fillMaxWidth().height(30.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(
                label.uppercase(),
                Modifier.weight(1f),
                color = MaterialTheme.colorScheme.outline,
                fontSize = 11.5.sp,
                fontWeight = FontWeight.Bold,
                letterSpacing = 1.sp,
            )
            AnimatedVisibility(
                edited,
                enter = fadeIn(tween(ms)) + expandHorizontally(tween(ms), expandFrom = Alignment.End),
                exit = fadeOut(tween(ms)) + shrinkHorizontally(tween(ms), shrinkTowards = Alignment.End),
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        stringResource(Res.string.edit_edited),
                        Modifier
                            .clip(CircleShape)
                            .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.16f))
                            .padding(horizontal = 8.dp, vertical = 2.dp),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.primary,
                    )
                    TextButton(
                        onUseSource,
                        Modifier.height(30.dp),
                        contentPadding = PaddingValues(horizontal = 10.dp),
                    ) {
                        Text(stringResource(Res.string.edit_use_source), style = MaterialTheme.typography.labelMedium)
                    }
                }
            }
        }
        content()
    }
}

// The genres as pills that each have a cross, with a field at the end that adds one, or several at once when they are split by commas.
@Composable
internal fun GenreEditor(genres: List<String>, onChange: (List<String>) -> Unit) {
    var typed by rememberSaveable { mutableStateOf("") }
    fun add() {
        val more = typed.split(',', '\n').map(String::trim).filter { it.isNotEmpty() && it !in genres }
        if (more.isNotEmpty()) onChange(genres + more)
        typed = ""
    }
    Column(Modifier.animateContentSize(), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        if (genres.isNotEmpty()) {
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                for (genre in genres) {
                    Row(
                        Modifier.height(32.dp).softCard(shape = CircleShape).padding(start = 12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        Text(genre, style = MaterialTheme.typography.labelLarge)
                        IconButton({ onChange(genres - genre) }, Modifier.size(32.dp)) {
                            Icon(
                                Icons.Outlined.Close,
                                stringResource(Res.string.remove),
                                Modifier.size(16.dp),
                                tint = MaterialTheme.colorScheme.outline,
                            )
                        }
                    }
                }
            }
        }
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            SoftField(
                typed,
                { typed = it },
                Modifier.weight(1f),
                hint = stringResource(Res.string.edit_genre_hint),
                onDone = ::add,
            )
            IconButton(
                ::add,
                enabled = typed.isNotBlank(),
            ) { Icon(Icons.Outlined.Add, stringResource(Res.string.edit_genre_hint)) }
        }
    }
}

// The cover and the ways to change it: a picture from a file, one from another source, or the source's own again once it was changed.
@Composable
internal fun CoverPanel(
    title: Title,
    custom: Boolean,
    wide: Boolean,
    onFile: () -> Unit,
    onSearch: () -> Unit,
    onSource: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val buttons: @Composable () -> Unit = {
        Column(Modifier.animateContentSize(), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            CoverChoice(Res.string.edit_cover_file, Icons.Outlined.UploadFile, onFile)
            CoverChoice(Res.string.edit_cover_sources, Icons.Outlined.ImageSearch, onSearch)
            if (custom) CoverChoice(Res.string.edit_cover_source, Icons.Outlined.Restore, onSource)
        }
    }
    if (wide) {
        Column(modifier, verticalArrangement = Arrangement.spacedBy(12.dp)) {
            CoverArt(title, Modifier.fillMaxWidth(), letterSize = 34)
            buttons()
        }
    } else {
        Row(
            modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(14.dp),
            verticalAlignment = Alignment.CenterVertically,
        ) {
            CoverArt(title, Modifier.width(104.dp), letterSize = 26)
            Column(Modifier.weight(1f)) { buttons() }
        }
    }
}

@Composable
private fun CoverChoice(text: StringResource, icon: ImageVector, onClick: () -> Unit) {
    CardButton(onClick, Modifier.fillMaxWidth()) {
        Icon(icon, null, Modifier.padding(start = 12.dp).size(20.dp), tint = MaterialTheme.colorScheme.primary)
        Text(
            stringResource(text),
            Modifier.padding(horizontal = 12.dp, vertical = 11.dp),
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium,
        )
    }
}
