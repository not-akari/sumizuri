package com.sumizuri.app.feature.tv.settings.system

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sumizuri.app.feature.tv.onboarding.firstFocus
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tv_off
import com.sumizuri.app.shared.resources.tv_on
import com.sumizuri.app.ui.tv.TvRow
import org.jetbrains.compose.resources.stringResource

// A page of the settings of a TV: its name and a line about it, then its rows, which scroll to follow the focus. The first row takes the focus.
@Composable
internal fun TvSystemPage(
    title: String,
    text: String?,
    modifier: Modifier = Modifier,
    content: @Composable ColumnScope.(FocusRequester) -> Unit,
) {
    val first = firstFocus()
    Column(
        modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = 56.dp, vertical = 36.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Text(title, fontSize = 34.sp, fontWeight = FontWeight.SemiBold)
        text?.let {
            Text(
                it,
                Modifier.widthIn(max = 640.dp).padding(bottom = 8.dp),
                fontSize = 17.sp,
                lineHeight = 24.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        Column(Modifier.widthIn(max = 760.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) { content(first) }
    }
}

// A row with a name, a line under it, and a word on the right that tells the value or what OK does.
@Composable
internal fun TvInfoRow(
    name: String,
    line: String?,
    value: String?,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    valueColor: Color = Color.Unspecified,
) {
    val colors = MaterialTheme.colorScheme
    TvRow(onClick, modifier) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(name, fontSize = 18.sp, color = colors.onSurface, maxLines = 1, overflow = TextOverflow.Ellipsis)
            line?.let {
                Text(
                    it,
                    fontSize = 14.sp,
                    color = colors.onSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        value?.let {
            Text(
                it,
                fontSize = 16.sp,
                fontWeight = FontWeight.SemiBold,
                color = if (valueColor == Color.Unspecified) colors.primary else valueColor,
                maxLines = 1,
            )
        }
    }
}

// A small heading over a group of rows.
@Composable
internal fun TvGroupTitle(text: String) {
    Text(
        text,
        Modifier.padding(top = 14.dp, start = 4.dp),
        fontSize = 15.sp,
        fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}

// The words for a switch that is on or off.
@Composable
internal fun onOffWords(): (Boolean) -> String {
    val on = stringResource(Res.string.tv_on)
    val off = stringResource(Res.string.tv_off)
    return { if (it) on else off }
}
