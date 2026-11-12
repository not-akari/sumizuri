package com.sumizuri.app.feature.title

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.cancel
import com.sumizuri.app.shared.resources.duplicate_add
import com.sumizuri.app.shared.resources.duplicate_open_hint
import com.sumizuri.app.shared.resources.duplicate_text
import com.sumizuri.app.shared.resources.duplicate_title
import com.sumizuri.app.ui.kit.dialog.AppDialog
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource

// A title of the library with the same name as the one being added, and the source it came from.
private class SameTitle(val id: Long, val name: String, val source: String)

// A title waiting to be added while the person is asked about the ones of the same name.
private class Waiting(val same: List<SameTitle>, val add: () -> Unit)

// Names count as the same when only their capitals, spaces and marks differ.
private fun String.plain(): String = lowercase().filter(Char::isLetterOrDigit)

// The shortest main part a name may be matched by, so a word of two or three letters does not match everything.
private const val LeastMain = 4

// A name in plain form, and its main part before a subtitle when it has one, so "Name: The Subtitle" and "Name" are found as one title.
private fun String.keys(): Set<String> {
    val main = split(':', '(', '[').first().substringBefore(" - ").plain()
    return setOfNotNull(plain().takeIf(String::isNotEmpty), main.takeIf { it.length >= LeastMain })
}

// Asks before a title joins the library when one of the same name and kind is in it already, and adds it at once when none is. A title can be opened from the question when the page has a way to open one.
@Composable
internal fun rememberDuplicateGuard(
    onOpen: ((Long) -> Unit)? = null,
): (name: String, kind: Kind, selfId: Long, add: () -> Unit) -> Unit {
    val container = LocalAppContainer.current
    val scope = rememberCoroutineScope()
    val open by rememberUpdatedState(onOpen)
    var waiting by remember { mutableStateOf<Waiting?>(null) }
    waiting?.let { asked ->
        AppDialog(
            onDismissRequest = { waiting = null },
            title = { Text(stringResource(Res.string.duplicate_title)) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    Text(stringResource(Res.string.duplicate_text))
                    for (title in asked.same) {
                        val opener = open
                        Column(
                            Modifier
                                .fillMaxWidth()
                                .then(
                                    if (opener ==
                                        null
                                    ) {
                                        Modifier
                                    } else {
                                        Modifier.clickable {
                                            waiting = null
                                            opener(title.id)
                                        }
                                    },
                                ).padding(vertical = 6.dp),
                        ) {
                            Text(
                                title.name,
                                style = MaterialTheme.typography.titleSmall,
                                color = if (opener ==
                                    null
                                ) {
                                    MaterialTheme.colorScheme.onSurface
                                } else {
                                    MaterialTheme.colorScheme.primary
                                },
                            )
                            Text(
                                title.source,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                            )
                        }
                    }
                    if (open != null) {
                        Text(
                            stringResource(Res.string.duplicate_open_hint),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant,
                        )
                    }
                }
            },
            confirmButton = {
                TextButton({
                    waiting = null
                    asked.add()
                }) { Text(stringResource(Res.string.duplicate_add)) }
            },
            dismissButton = { TextButton({ waiting = null }) { Text(stringResource(Res.string.cancel)) } },
        )
    }
    return remember(container) {
        { name, kind, selfId, add ->
            scope.launch {
                val wanted = name.keys()
                val sameNamed = container.database.titles().libraryNames().filter {
                    it.id != selfId &&
                        it.kind == kind.code &&
                        wanted.isNotEmpty() &&
                        it.name.keys().any(wanted::contains)
                }
                if (sameNamed.isEmpty()) {
                    add()
                } else {
                    val sources = container.sources.installed
                        .first()
                        .associate { it.id to it.name }
                    waiting =
                        Waiting(sameNamed.map { SameTitle(it.id, it.name, sources[it.sourceId] ?: it.sourceId) }, add)
                }
            }
        }
    }
}
