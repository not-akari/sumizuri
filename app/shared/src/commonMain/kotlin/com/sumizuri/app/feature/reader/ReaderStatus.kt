package com.sumizuri.app.feature.reader

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.library.ChapterLock
import com.sumizuri.app.data.library.chapterLock
import com.sumizuri.app.data.model.ChapterPlace
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.back
import com.sumizuri.app.shared.resources.challenge_open
import com.sumizuri.app.shared.resources.reader_locked
import com.sumizuri.app.shared.resources.reader_locked_left
import com.sumizuri.app.shared.resources.reader_locked_on
import com.sumizuri.app.shared.resources.reader_locked_text
import com.sumizuri.app.shared.resources.reader_open_website
import com.sumizuri.app.shared.resources.try_again
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.card.softFill
import com.sumizuri.app.ui.kit.cover.shownName
import com.sumizuri.app.ui.kit.input.ActionButton
import com.sumizuri.app.ui.kit.web.LocalOpenSite
import com.sumizuri.app.ui.text.numberedUnit
import org.jetbrains.compose.resources.stringResource

// What the reader shows while the chapter is coming in, or why it cannot be shown, in the opening the player shares. The names of the reader win, and until it has them the ones the opener knew show, so the card is there from the start.
@Composable
fun ReaderStatus(
    state: ReaderState,
    onRetry: () -> Unit,
    onSolve: () -> Unit,
    onBack: () -> Unit,
    opening: ChapterPlace? = null,
) {
    val own = state.titleName.isNotEmpty()
    val known = own || opening != null
    val givenName = if (own) state.chapterName else opening?.name?.takeIf { it.isNotBlank() }
    // A chapter whose name says the site holds it back is named without that note, and a failure to open it shows the lock.
    val lock = remember(givenName) { chapterLock(givenName) }
    val chapterName = lock?.name ?: givenName
    val number = if (own) state.chapterNumber else opening?.number ?: 0.0
    val message = state.message
    ChapterOpening(
        cover = state.coverUrl ?: opening?.coverUrl,
        sourceId = state.sourceId ?: opening?.sourceId,
        heading = if (known) chapterName ?: numberedUnit(opening?.kind ?: state.kind, number) else null,
        titleName = state.titleName.ifEmpty { opening?.titleName.orEmpty() },
        onBack = onBack,
        now = message != null,
        bottom = message?.let {
            {
                if (lock != null && state.challengeUrl == null) {
                    Locked(lock, state.sourceId ?: opening?.sourceId, state.webUrl, onRetry, onBack)
                } else {
                    Failure(it, state.challengeUrl != null, onRetry, onSolve)
                }
            }
        },
    )
}

// Why the chapter cannot be shown, with the ways out under it.
@Composable
private fun Failure(message: ReaderMessage, challenge: Boolean, onRetry: () -> Unit, onSolve: () -> Unit) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Icon(Icons.Outlined.ErrorOutline, null, Modifier.size(32.dp), tint = MaterialTheme.colorScheme.error)
        Text(messageText(message), style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center)
        InkButton(onRetry) { Text(stringResource(Res.string.try_again)) }
        if (challenge) ActionButton(Res.string.challenge_open, onSolve)
    }
}

// A chapter the site holds back: a lock, the site that holds it, how long it said was left, and the ways out, which are trying again, the website and back.
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun Locked(lock: ChapterLock, sourceId: String?, webUrl: String?, onRetry: () -> Unit, onBack: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    val container = LocalAppContainer.current
    val installed by remember(container) { container.sources.installed }.collectAsStateWithLifecycle(emptyList())
    val site = installed.firstOrNull { it.id == sourceId }?.shownName()
    val openSite = LocalOpenSite.current
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(10.dp)) {
        Box(
            Modifier.size(56.dp).clip(CircleShape).background(softFill(strong = true)),
            contentAlignment = Alignment.Center,
        ) { Icon(Icons.Rounded.Lock, null, Modifier.size(26.dp), tint = colors.primary) }
        Text(
            site?.let { stringResource(Res.string.reader_locked_on, it) } ?: stringResource(Res.string.reader_locked),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.SemiBold,
            textAlign = TextAlign.Center,
        )
        Text(
            lock.left?.let { stringResource(Res.string.reader_locked_left, it) }
                ?: stringResource(Res.string.reader_locked_text),
            style = MaterialTheme.typography.bodyMedium,
            color = colors.onSurfaceVariant,
            textAlign = TextAlign.Center,
        )
        FlowRow(
            Modifier.padding(top = 6.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            InkButton(onRetry) { Text(stringResource(Res.string.try_again)) }
            if (webUrl != null) ActionButton(Res.string.reader_open_website, { openSite(webUrl) })
            TextButton(onBack) { Text(stringResource(Res.string.back)) }
        }
    }
}

@Composable
private fun messageText(message: ReaderMessage): String = when (message) {
    is ReaderMessage.Fixed -> stringResource(message.text)
    is ReaderMessage.Detail -> message.text
}
