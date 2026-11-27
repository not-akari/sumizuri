package com.sumizuri.app.feature.lists

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.lists.Added
import com.sumizuri.app.data.lists.ListCountLimit
import com.sumizuri.app.data.lists.ListSizeLimit
import com.sumizuri.app.data.lists.MakeResult
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.list_full
import com.sumizuri.app.shared.resources.list_left_out
import com.sumizuri.app.shared.resources.lists_full
import com.sumizuri.app.shared.resources.lists_taken
import com.sumizuri.app.ui.theme.LocalReduceMotion
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// Something a change to the lists could not do, said in a line under where it was asked.
internal sealed interface ListNotice {
    data object Taken : ListNotice
    data object TooMany : ListNotice
    data object Full : ListNotice
    data class LeftOut(val count: Int) : ListNotice
}

internal fun MakeResult.notice(): ListNotice? = when (this) {
    MakeResult.Taken -> ListNotice.Taken
    MakeResult.Full -> ListNotice.TooMany
    else -> null
}

// What adding said: nothing when every title went on, and how many did not fit when a list ran out of room.
internal fun Added.notice(): ListNotice? = when {
    leftOut > 0 && added == 0 -> ListNotice.Full
    leftOut > 0 -> ListNotice.LeftOut(leftOut)
    else -> null
}

// The line of a notice, which slides in and out.
@Composable
internal fun NoticeLine(notice: ListNotice?, modifier: Modifier = Modifier) {
    val reduce = LocalReduceMotion.current
    val shown = remember { arrayOfNulls<ListNotice>(1) }
    if (notice != null) shown[0] = notice
    AnimatedVisibility(
        notice != null,
        modifier,
        enter = if (reduce) fadeIn() else fadeIn() + expandVertically(),
        exit = if (reduce) fadeOut() else fadeOut() + shrinkVertically(),
    ) {
        val text = when (val last = shown[0]) {
            ListNotice.Taken -> stringResource(Res.string.lists_taken)

            ListNotice.TooMany -> stringResource(Res.string.lists_full, ListCountLimit)

            ListNotice.Full -> stringResource(Res.string.list_full, ListSizeLimit)

            is ListNotice.LeftOut -> pluralStringResource(
                Res.plurals.list_left_out,
                last.count,
                last.count,
                ListSizeLimit,
            )

            null -> ""
        }
        Text(
            text,
            Modifier.padding(horizontal = 14.dp, vertical = 6.dp),
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.error,
        )
    }
}
