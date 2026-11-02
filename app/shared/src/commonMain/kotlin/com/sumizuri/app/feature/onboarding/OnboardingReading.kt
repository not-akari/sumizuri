package com.sumizuri.app.feature.onboarding

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.keyframes
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.clipRect
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.reader.ReaderMode
import com.sumizuri.app.feature.reader.controls.icon
import com.sumizuri.app.feature.settings.GlobalReaderViewModel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.onboarding_mode_continuous_hint
import com.sumizuri.app.shared.resources.onboarding_mode_ltr_hint
import com.sumizuri.app.shared.resources.onboarding_mode_rtl_hint
import com.sumizuri.app.shared.resources.onboarding_mode_vertical_hint
import com.sumizuri.app.shared.resources.onboarding_reading_sample
import com.sumizuri.app.shared.resources.onboarding_reading_text
import com.sumizuri.app.shared.resources.onboarding_reading_title
import com.sumizuri.app.shared.resources.reader_text_size
import com.sumizuri.app.ui.kit.art.rise
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SliderSetting
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource
import kotlin.math.roundToInt

// How manga pages turn, shown turning in a little screen, and how large the text of novels is, shown on a line of a story as it is set.
@Composable
internal fun ReadingStep() {
    val container = LocalAppContainer.current
    val model = viewModel { GlobalReaderViewModel(container.reading) }
    val settings by model.settings.collectAsStateWithLifecycle()
    StepHeader(stringResource(Res.string.onboarding_reading_title), stringResource(Res.string.onboarding_reading_text))
    BoxWithConstraints(Modifier.fillMaxWidth().rise(2)) {
        val wide = maxWidth > 520.dp
        // The modes sit in a card of the settings, each marked the way the panel of modes in the reader marks the one in use.
        val options: @Composable () -> Unit = {
            SettingsSection {
                padded {
                    Column(Modifier.padding(vertical = 4.dp), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        for (mode in ReaderMode.entries) {
                            ModeOption(
                                mode,
                                mode == settings.mode,
                            ) { model.update { it.copy(mode = mode) } }
                        }
                    }
                }
            }
        }
        if (wide) {
            Row(horizontalArrangement = Arrangement.spacedBy(20.dp), verticalAlignment = Alignment.CenterVertically) {
                PagePreview(settings.mode, Modifier.width(132.dp))
                Column(Modifier.weight(1f)) { options() }
            }
        } else {
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp),
            ) {
                PagePreview(settings.mode, Modifier.width(120.dp))
                options()
            }
        }
    }
    var live by remember(settings.fontSize) { mutableFloatStateOf(settings.fontSize.toFloat()) }
    val shown by animateFloatAsState(live, tween(160), label = "text size")
    Column(Modifier.rise(3), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        SettingsSection {
            padded {
                SliderSetting(Res.string.reader_text_size, settings.fontSize.toFloat(), 12f..40f, {
                    it.roundToInt().toString()
                }, onMove = {
                    live =
                        it
                }) { value ->
                    model.update { it.copy(fontSize = value.roundToInt()) }
                }
            }
        }
        AppCard(Modifier.fillMaxWidth()) {
            Text(
                stringResource(Res.string.onboarding_reading_sample),
                Modifier.padding(16.dp),
                fontSize = shown.sp,
                lineHeight = (
                    shown *
                        1.6f
                    ).sp,
            )
        }
    }
}

// One way pages can turn: the icon the reader shows for it, its name and a line about it, on a soft fill with a tick when it is the one chosen.
@Composable
private fun ModeOption(mode: ReaderMode, selected: Boolean, onClick: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    val back by animateColorAsState(if (selected) colors.secondaryContainer else Color.Transparent, label = "mode back")
    Row(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(back)
            .clickable(role = Role.RadioButton, onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(14.dp),
    ) {
        Icon(mode.icon(), null, tint = if (selected) colors.onSecondaryContainer else colors.onSurfaceVariant)
        Column(Modifier.weight(1f)) {
            Text(
                stringResource(mode.label),
                style = MaterialTheme.typography.bodyLarge,
                color = if (selected) colors.onSecondaryContainer else colors.onSurface,
                fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
            )
            Text(
                stringResource(mode.hint()),
                style = MaterialTheme.typography.bodySmall,
                color = colors.onSurfaceVariant,
            )
        }
        if (selected) Icon(Icons.Outlined.Check, null, tint = colors.primary)
    }
}

private fun ReaderMode.hint(): StringResource = when (this) {
    ReaderMode.Continuous -> Res.string.onboarding_mode_continuous_hint
    ReaderMode.RightToLeft -> Res.string.onboarding_mode_rtl_hint
    ReaderMode.LeftToRight -> Res.string.onboarding_mode_ltr_hint
    ReaderMode.Vertical -> Res.string.onboarding_mode_vertical_hint
}

// A small screen with pages of panels turning as the way chosen turns them: across from the side the next page comes from, down one at a time, or one strip flowing up.
@Composable
private fun PagePreview(mode: ReaderMode, modifier: Modifier) {
    val transition = rememberInfiniteTransition(label = "pages")
    val turn by transition.animateFloat(
        0f,
        1f,
        infiniteRepeatable(
            keyframes {
                durationMillis = 2_200
                0f at 0
                0f at 1_200
                1f at 1_800 using FastOutSlowInEasing
                1f at 2_200
            },
        ),
        label = "turn",
    )
    val flow by transition.animateFloat(0f, 1f, infiniteRepeatable(tween(4_000, easing = LinearEasing)), label = "flow")
    val colors = MaterialTheme.colorScheme
    val frame = RoundedCornerShape(18.dp)
    Canvas(
        modifier
            .size(width = 132.dp, height = 210.dp)
            .clip(frame)
            .background(colors.surfaceContainerHigh)
            .border(2.dp, colors.outlineVariant, frame),
    ) {
        val inset = 8.dp.toPx()
        val page = Size(size.width - inset * 2, size.height - inset * 2)
        clipRect(inset, inset, size.width - inset, size.height - inset) {
            when (mode) {
                // The page read moves off to the right and the next one comes in from the left.
                ReaderMode.RightToLeft -> for (i in 0..1) {
                    drawPage(
                        Offset(inset + (turn - i) * page.width, inset),
                        page,
                        i,
                        colors.primary,
                        colors.onSurfaceVariant,
                    )
                }

                ReaderMode.LeftToRight -> for (i in 0..1) {
                    drawPage(
                        Offset(inset + (i - turn) * page.width, inset),
                        page,
                        i,
                        colors.primary,
                        colors.onSurfaceVariant,
                    )
                }

                ReaderMode.Vertical -> for (i in 0..1) {
                    drawPage(
                        Offset(inset, inset + (i - turn) * page.height),
                        page,
                        i,
                        colors.primary,
                        colors.onSurfaceVariant,
                    )
                }

                ReaderMode.Continuous -> {
                    val strip = page.height * 0.6f
                    for (i in -1..3) {
                        drawPage(
                            Offset(inset, inset + (i - flow) * strip),
                            Size(
                                page.width,
                                strip - 4.dp.toPx(),
                            ),
                            i,
                            colors.primary,
                            colors.onSurfaceVariant,
                        )
                    }
                }
            }
        }
    }
}

// One page of the preview: a sheet with a few panels on it, every other one tinted so the turning reads.
private fun DrawScope.drawPage(at: Offset, page: Size, index: Int, accent: Color, ink: Color) {
    drawRoundRect(
        if (index % 2 ==
            0
        ) {
            accent.copy(alpha = 0.18f)
        } else {
            ink.copy(alpha = 0.12f)
        },
        at,
        page,
        CornerRadius(8.dp.toPx()),
    )
    val gap = 5.dp.toPx()
    val top = Size(page.width - gap * 2, page.height * 0.38f)
    drawRoundRect(ink.copy(alpha = 0.22f), at + Offset(gap, gap), top, CornerRadius(4.dp.toPx()))
    val half = Size((page.width - gap * 3) / 2, page.height - top.height - gap * 3)
    drawRoundRect(ink.copy(alpha = 0.16f), at + Offset(gap, top.height + gap * 2), half, CornerRadius(4.dp.toPx()))
    drawRoundRect(
        accent.copy(alpha = 0.28f),
        at + Offset(gap * 2 + half.width, top.height + gap * 2),
        half,
        CornerRadius(4.dp.toPx()),
    )
}
