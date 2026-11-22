package com.sumizuri.app.feature.tv.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.feature.theme.rememberThemeModel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.onboarding_next
import com.sumizuri.app.shared.resources.tv_look_text
import com.sumizuri.app.shared.resources.tv_look_title
import com.sumizuri.app.ui.theme.ThemeWipe
import com.sumizuri.app.ui.theme.colorScheme
import com.sumizuri.app.ui.theme.spec.AppThemeSpec
import com.sumizuri.app.ui.theme.spec.ThemePresets
import com.sumizuri.app.ui.tv.TvButton
import com.sumizuri.app.ui.tv.tvCard
import kotlinx.coroutines.delay
import org.jetbrains.compose.resources.stringResource

// How many themes stand in one row.
private const val PerRow = 6

// The themes that come with the app as two rows of small pages in their own colors. OK on one uses it at once, so the whole screen takes it, and the one in use has a tick. The remote starts on the one in use.
@Composable
internal fun LookStep(step: TvStep, onNext: () -> Unit) {
    Column(Modifier.fillMaxSize().padding(horizontal = 72.dp, vertical = 40.dp)) {
        StepDots(step)
        Row(Modifier.fillMaxWidth().padding(top = 28.dp, bottom = 26.dp), verticalAlignment = Alignment.Bottom) {
            Column(Modifier.weight(1f)) {
                Text(stringResource(Res.string.tv_look_title), fontSize = 36.sp, fontWeight = FontWeight.SemiBold)
                Text(
                    stringResource(Res.string.tv_look_text),
                    Modifier.padding(top = 10.dp).widthIn(max = 600.dp),
                    fontSize = 18.sp,
                    lineHeight = 26.sp,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            TvButton(stringResource(Res.string.onboarding_next), onNext)
        }
        ThemeGrid()
        Spacer(Modifier.weight(1f))
    }
}

// The themes in rows. OK on one uses it at once, and the one in use takes the first focus once the theme is read, or the first theme when the one in use is a theme of the person's own. Every tile keeps its own focus place, so a pick changes nothing the focus is held by.
@Composable
internal fun ThemeGrid() {
    val model = rememberThemeModel()
    val active by model.active.collectAsStateWithLifecycle()
    val read by model.read.collectAsStateWithLifecycle()
    val dark = MaterialTheme.colorScheme.surface.luminance() < 0.5f
    val places = remember { ThemePresets.map { FocusRequester() } }
    LaunchedEffect(read) {
        if (!read) return@LaunchedEffect
        val start = ThemePresets.indexOfFirst { it.id == active.id }.coerceAtLeast(0)
        repeat(4) {
            delay(150)
            runCatching { places[start].requestFocus() }
        }
    }
    Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
        for (row in ThemePresets.chunked(PerRow)) {
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                for (theme in row) {
                    ThemeTile(
                        theme,
                        dark,
                        theme.id == active.id,
                        { model.select(theme.id) },
                        Modifier.weight(1f).focusRequester(places[ThemePresets.indexOf(theme)]),
                    )
                }
            }
        }
    }
}

// One theme: a small page in its colors with a title line, a text line, a button and a chip, and its name under it.
@Composable
private fun ThemeTile(theme: AppThemeSpec, dark: Boolean, chosen: Boolean, onPick: () -> Unit, modifier: Modifier) {
    val scheme = remember(theme, dark) { theme.colorScheme(dark) }
    // Ink in the page color of the new look spreads out from the middle of the card, kept where it was last laid out, and the look changes under it.
    val center = remember { arrayOf(Offset.Zero) }
    val pick = { if (!chosen) ThemeWipe.start(scheme.background, center[0], onPick) }
    Column(
        modifier
            .onGloballyPositioned { center[0] = it.boundsInRoot().center }
            .tvCard(
                pick,
                chosen = chosen,
            ).padding(10.dp),
        verticalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Box(
            Modifier
                .fillMaxWidth()
                .height(70.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(scheme.surface)
                .padding(10.dp),
        ) {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Box(
                    Modifier
                        .width(48.dp)
                        .height(7.dp)
                        .clip(CircleShape)
                        .background(scheme.onSurface),
                )
                Box(
                    Modifier
                        .fillMaxWidth(0.75f)
                        .height(5.dp)
                        .clip(CircleShape)
                        .background(scheme.outline),
                )
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Box(
                        Modifier
                            .width(30.dp)
                            .height(16.dp)
                            .clip(CircleShape)
                            .background(scheme.primary),
                    )
                    Box(
                        Modifier
                            .width(22.dp)
                            .height(16.dp)
                            .clip(CircleShape)
                            .background(scheme.tertiary),
                    )
                }
            }
        }
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                theme.name,
                Modifier.weight(1f),
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            if (chosen) {
                Icon(
                    Icons.Rounded.CheckCircle,
                    null,
                    Modifier.size(18.dp),
                    tint = MaterialTheme.colorScheme.primary,
                )
            }
        }
    }
}
