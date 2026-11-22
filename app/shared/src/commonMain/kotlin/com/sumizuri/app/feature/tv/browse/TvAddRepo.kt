package com.sumizuri.app.feature.tv.browse

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tv_add_repo
import com.sumizuri.app.shared.resources.tv_add_repo_text
import com.sumizuri.app.shared.resources.tv_repo_add
import com.sumizuri.app.shared.resources.tv_repo_check
import com.sumizuri.app.shared.resources.tv_repo_checking
import com.sumizuri.app.shared.resources.tv_repo_clear
import com.sumizuri.app.shared.resources.tv_repo_found
import com.sumizuri.app.shared.resources.tv_repo_not_address
import com.sumizuri.app.source.SourceResult
import com.sumizuri.app.source.repo.RepoIndex
import com.sumizuri.app.ui.kit.input.AppTextField
import com.sumizuri.app.ui.tv.TvButton
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The start every address has, already in the field.
private const val Start = "https://"

// Pieces of an address that are slow to type with a remote, each added where the field ends.
private val QuickKeys = listOf("github.com/", "raw.githubusercontent.com/", ".com", ".io", ".net", ".org", "/", "index.json")

// What the check of an address found: nothing yet, under way, a repo with its name and how many sources it has, or why it failed.
private sealed interface Checked {
    data object None : Checked

    data object Busy : Checked

    data class Found(val name: String, val all: Int, val videos: Int) : Checked

    data class Failed(val why: String) : Checked
}

// The page that adds a repo with a remote: a large field that starts with https://, keys for the parts of addresses that take long to type, a check that reads the repo and says its name and how many sources it has, and the button that adds it.
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun TvAddRepo(onCheck: suspend (String) -> SourceResult<RepoIndex>, onAdd: (String) -> Unit) {
    var address by remember { mutableStateOf(TextFieldValue(Start, TextRange(Start.length))) }
    var checked by remember { mutableStateOf<Checked>(Checked.None) }
    val scope = rememberCoroutineScope()
    val first = remember { FocusRequester() }
    LaunchedEffect(Unit) {
        repeat(4) {
            delay(150)
            runCatching { first.requestFocus() }
        }
    }
    val notAddress = stringResource(Res.string.tv_repo_not_address)
    val check: () -> Unit = {
        val url = address.text.trim()
        if (!url.startsWith("http://") && !url.startsWith("https://")) {
            checked = Checked.Failed(notAddress)
        } else {
            checked = Checked.Busy
            scope.launch {
                checked = when (val result = onCheck(url)) {
                    is SourceResult.Ok -> Checked.Found(result.value.name.ifBlank { url }, result.value.sources.size, result.value.sources.count { it.kind == Kind.Anime })
                    is SourceResult.Err -> Checked.Failed(result.error.message)
                }
            }
        }
    }
    fun append(piece: String) {
        val text = address.text + piece
        address = TextFieldValue(text, TextRange(text.length))
        checked = Checked.None
    }
    Column(
        Modifier.fillMaxSize().padding(horizontal = 72.dp, vertical = 40.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text(stringResource(Res.string.tv_add_repo), fontSize = 34.sp, fontWeight = FontWeight.SemiBold)
        Text(
            stringResource(Res.string.tv_add_repo_text),
            Modifier.widthIn(max = 640.dp),
            fontSize = 17.sp,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        AppTextField(
            address,
            {
                address = it
                checked = Checked.None
            },
            Modifier.fillMaxWidth(),
            singleLine = true,
            textStyle = MaterialTheme.typography.titleLarge,
        )
        FlowRow(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            QuickKeys.forEachIndexed { at, piece ->
                TvButton(piece, { append(piece) }, if (at == 0) Modifier.focusRequester(first) else Modifier, main = false)
            }
            TvButton(stringResource(Res.string.tv_repo_clear), {
                address = TextFieldValue(Start, TextRange(Start.length))
                checked = Checked.None
            }, main = false)
        }
        val shown = checked
        val line = when (shown) {
            Checked.None -> null
            Checked.Busy -> stringResource(Res.string.tv_repo_checking)
            is Checked.Found -> shown.name + "  ·  " + pluralStringResource(Res.plurals.tv_repo_found, shown.all, shown.all, shown.videos)
            is Checked.Failed -> shown.why
        }
        if (line != null) {
            Text(
                line,
                fontSize = 18.sp,
                color = if (shown is Checked.Failed) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.primary,
            )
        }
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
            if (shown is Checked.Found) {
                TvButton(stringResource(Res.string.tv_repo_add), { onAdd(address.text.trim()) })
            } else {
                TvButton(stringResource(Res.string.tv_repo_check), check)
            }
        }
    }
}
