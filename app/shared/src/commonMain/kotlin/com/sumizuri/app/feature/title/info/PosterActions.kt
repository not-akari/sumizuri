package com.sumizuri.app.feature.title.info

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Comment
import androidx.compose.material.icons.filled.LibraryAddCheck
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.LibraryAdd
import androidx.compose.material.icons.outlined.StarBorder
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.feature.title.TitleCallbacks
import com.sumizuri.app.feature.title.TitleState
import com.sumizuri.app.feature.title.chapter.InGroupGap
import com.sumizuri.app.feature.trackers.TrackersAction
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.comments_title
import com.sumizuri.app.shared.resources.title_add
import com.sumizuri.app.shared.resources.title_favorite
import com.sumizuri.app.shared.resources.title_in_library
import com.sumizuri.app.ui.kit.card.ActionStrip
import com.sumizuri.app.ui.kit.card.StripAction
import com.sumizuri.app.ui.kit.card.cardFill
import org.jetbrains.compose.resources.stringResource

// The actions of a title as parts of a strip, at the foot of the continue card: the library, the favorite star when there is one, the trackers of a saved title, and the comments when the source has them. The rest of what can be done with the title is in the menu of the bar at the top.
@Composable
internal fun RowScope.TitleStripActions(state: TitleState, title: Title, calls: TitleCallbacks, ink: Color) {
    val saved = title.inLibrary && !state.preview
    // The library has an icon of its own, so the heart is not mistaken for the favourite, which is the star everywhere.
    StripAction(
        stringResource(if (saved) Res.string.title_in_library else Res.string.title_add),
        on = saved,
        ink = ink,
        accent = MaterialTheme.colorScheme.primary,
        onClick = calls.onToggleLibrary,
        first = true,
        enabled = saved || !state.loading || !state.preview,
    ) { tint ->
        Icon(
            if (saved) Icons.Filled.LibraryAddCheck else Icons.Outlined.LibraryAdd,
            null,
            Modifier.size(18.dp),
            tint = tint,
        )
    }
    if (saved && state.favoritesEnabled) {
        StripAction(
            stringResource(Res.string.title_favorite),
            on = title.favorite,
            ink = ink,
            accent = MaterialTheme.colorScheme.primary,
            onClick = calls.onToggleFavorite,
        ) { tint ->
            Icon(
                if (title.favorite) Icons.Filled.Star else Icons.Outlined.StarBorder,
                null,
                Modifier.size(18.dp),
                tint = tint,
            )
        }
    }
    if (saved) TrackersAction(title, ink)
    // The comments can be read before the title is saved.
    state.comments?.let { target ->
        StripAction(stringResource(Res.string.comments_title), on = false, ink = ink, onClick = {
            calls.onComments(target)
        }) { tint ->
            Icon(Icons.AutoMirrored.Outlined.Comment, null, Modifier.size(18.dp), tint = tint)
        }
    }
}

// The actions joined in one plain bar under the continue card, in the color of every card, so only the continue card is bright. The icon of an action that is on takes the accent.
@Composable
internal fun TitleActionCard(state: TitleState, title: Title, calls: TitleCallbacks, modifier: Modifier = Modifier) {
    val shape = MaterialTheme.shapes.large
    Column(modifier.fillMaxWidth().clip(shape)) {
        ActionStrip(
            MaterialTheme.colorScheme.onSurface,
            shade = cardFill(),
        ) { ink -> TitleStripActions(state, title, calls, ink) }
    }
}

// The continue card with the bar of actions under it, the same in every layout. A title that cannot be reached says why above them instead.
@Composable
internal fun ContinueBlock(state: TitleState, title: Title, calls: TitleCallbacks, modifier: Modifier = Modifier) {
    Column(modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(InGroupGap)) {
        if (!state.readable) UnreachableActions(state, title, calls, Modifier.fillMaxWidth())
        val target = state.target
        if (state.readable && target != null) ContinueButton(target, title.kind, state.chapters, calls.onContinue)
        TitleActionCard(state, title, calls)
    }
}
