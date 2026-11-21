package com.sumizuri.app.setup

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.SizeTransform
import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.hoverable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Remove
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.setup_close
import com.sumizuri.app.shared.resources.setup_fact_version
import com.sumizuri.app.shared.resources.setup_minimize
import com.sumizuri.app.shared.resources.setup_step_done
import com.sumizuri.app.shared.resources.setup_step_install
import com.sumizuri.app.shared.resources.setup_step_options
import com.sumizuri.app.shared.resources.setup_step_remove
import com.sumizuri.app.shared.resources.setup_step_removed
import com.sumizuri.app.shared.resources.setup_step_welcome
import com.sumizuri.app.ui.kit.art.AnimatedLogo
import com.sumizuri.app.ui.kit.step.StepTrack
import com.sumizuri.app.ui.theme.background.ambientBackground
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource
import java.io.File
import java.awt.Window as AwtWindow

// The room the pages keep from the sides of the card.
private val Side = 40.dp

// The card of the setup in one column: the name and the buttons of the window at the top, the steps under them, then the page with its soft bar of buttons at the bottom.
@Composable
internal fun SetupCard(
    model: SetupModel,
    window: AwtWindow?,
    log: File,
    onMinimize: () -> Unit,
    onClose: () -> Unit,
    drag: @Composable (Modifier, @Composable () -> Unit) -> Unit,
) {
    val shape = RoundedCornerShape(18.dp)
    Box(Modifier.fillMaxSize().padding(ShadowRoom)) {
        Column(
            Modifier
                .fillMaxSize()
                .shadow(
                    26.dp,
                    shape,
                    ambientColor = Color.Black.copy(alpha = 0.5f),
                    spotColor = Color.Black.copy(alpha = 0.6f),
                ).clip(shape)
                .ambientBackground()
                .border(1.dp, MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.45f), shape),
        ) {
            drag(Modifier.fillMaxWidth()) {
                Column {
                    TopBar(model, onMinimize, onClose)
                    Steps(model)
                }
            }
            Pages(model, window, log, onClose, Modifier.weight(1f))
        }
    }
}

// The logo, the name and the version on the left, and the buttons of the window on the right.
@Composable
private fun TopBar(model: SetupModel, onMinimize: () -> Unit, onClose: () -> Unit) {
    Row(
        Modifier.fillMaxWidth().height(56.dp).padding(start = 18.dp, end = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        AnimatedLogo(30.dp)
        Text("Sumizuri", style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.Bold)
        Text(
            stringResource(Res.string.setup_fact_version, model.version),
            Modifier.weight(1f),
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.outline,
        )
        BarButton(Icons.Rounded.Remove, stringResource(Res.string.setup_minimize), onMinimize)
        BarButton(
            Icons.Rounded.Close,
            stringResource(Res.string.setup_close),
            onClose,
            enabled = model.canClose,
            danger = true,
        )
    }
}

// The steps of the way the person goes, on the shared step track. A failure sits on the install step, and the removal shows on the first step while it runs.
@Composable
private fun Steps(model: SetupModel) {
    val rail = model.rail
    val on = when (model.step) {
        SetupStep.Failed -> SetupStep.Working
        SetupStep.Working -> if (model.mode == SetupMode.Uninstall) SetupStep.Remove else SetupStep.Working
        else -> model.step
    }
    StepTrack(
        rail.map { stringResource(it.label()) },
        rail.indexOf(on).coerceAtLeast(0),
        // The same room above the track as below it, counted from the logo above and the page below.
        Modifier.padding(horizontal = Side - 4.dp).padding(top = 20.dp, bottom = 12.dp),
    )
}

private fun SetupStep.label(): StringResource = when (this) {
    SetupStep.Welcome -> Res.string.setup_step_welcome
    SetupStep.Options -> Res.string.setup_step_options
    SetupStep.Working, SetupStep.Failed -> Res.string.setup_step_install
    SetupStep.Done -> Res.string.setup_step_done
    SetupStep.Remove -> Res.string.setup_step_remove
    SetupStep.Removed -> Res.string.setup_step_removed
}

// A round button of the window bar that lights up under the mouse, red for closing as Windows does.
@Composable
private fun BarButton(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit,
    enabled: Boolean = true,
    danger: Boolean = false,
) {
    val source = remember { MutableInteractionSource() }
    val hovered by source.collectIsHoveredAsState()
    val lit = hovered && enabled
    val back by animateColorAsState(
        when {
            !lit -> Color.Transparent
            danger -> Color(0xFFE81123)
            else -> MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f)
        },
        label = "back",
    )
    val tint by animateColorAsState(
        if (lit &&
            danger
        ) {
            Color.White
        } else {
            MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = if (enabled) 1f else 0.35f)
        },
        label = "tint",
    )
    Box(
        Modifier
            .size(
                36.dp,
            ).clip(
                CircleShape,
            ).background(back)
            .hoverable(source)
            .clickable(source, null, enabled = enabled, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) { Icon(icon, label, Modifier.size(18.dp), tint = tint) }
}

// The page of the step the person is on. A step forward slides in from the right and a step back from the left.
@Composable
private fun Pages(model: SetupModel, window: AwtWindow?, log: File, onClose: () -> Unit, modifier: Modifier) {
    AnimatedContent(
        model.step,
        modifier.fillMaxSize(),
        transitionSpec = {
            val forward = targetState.ordinal >= initialState.ordinal
            val enter =
                slideInHorizontally(tween(440, easing = FastOutSlowInEasing)) { if (forward) it / 5 else -it / 5 } +
                    fadeIn(tween(320, delayMillis = 80))
            val exit =
                slideOutHorizontally(tween(300, easing = FastOutSlowInEasing)) { if (forward) -it / 6 else it / 6 } +
                    fadeOut(tween(200))
            enter togetherWith exit using SizeTransform(clip = false)
        },
        label = "page",
    ) { step ->
        Box(Modifier.fillMaxSize().padding(start = Side, end = Side, top = 4.dp, bottom = 20.dp)) {
            when (step) {
                SetupStep.Welcome -> WelcomePage(model)
                SetupStep.Options -> OptionsPage(model, window)
                SetupStep.Working -> WorkingPage(model)
                SetupStep.Done -> DonePage(model, onClose)
                SetupStep.Failed -> FailedPage(model, log, onClose)
                SetupStep.Remove -> RemovePage(model, onClose)
                SetupStep.Removed -> RemovedPage(model, onClose)
            }
        }
    }
}
