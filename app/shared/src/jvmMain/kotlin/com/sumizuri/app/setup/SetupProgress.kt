package com.sumizuri.app.setup

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Lightbulb
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.setup_copied
import com.sumizuri.app.shared.resources.setup_phase_close
import com.sumizuri.app.shared.resources.setup_phase_copy
import com.sumizuri.app.shared.resources.setup_phase_finish
import com.sumizuri.app.shared.resources.setup_phase_old
import com.sumizuri.app.shared.resources.setup_phase_shortcuts
import com.sumizuri.app.shared.resources.setup_phase_unpack
import com.sumizuri.app.shared.resources.setup_tip_backup
import com.sumizuri.app.shared.resources.setup_tip_downloads
import com.sumizuri.app.shared.resources.setup_tip_search
import com.sumizuri.app.shared.resources.setup_tip_theme
import com.sumizuri.app.shared.resources.setup_tip_title
import com.sumizuri.app.shared.resources.setup_working_install
import com.sumizuri.app.shared.resources.setup_working_remove
import com.sumizuri.app.shared.resources.setup_working_update
import com.sumizuri.app.ui.kit.art.rise
import com.sumizuri.app.ui.kit.card.softFill
import com.sumizuri.app.ui.text.byteSizeText
import kotlinx.coroutines.delay
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource
import kotlin.math.roundToInt

// The install going on: its title, the part running now, a wide bar of the whole work with its share and how much is copied, the parts as chips, and the tips and the log under them.
@Composable
internal fun WorkingPage(model: SetupModel) {
    val copied by model.copied.collectAsState()
    val removing = model.mode == SetupMode.Uninstall
    val progress = if (removing) null else model.progress()
    val title = when {
        removing -> Res.string.setup_working_remove
        model.updating -> Res.string.setup_working_update
        else -> Res.string.setup_working_install
    }
    val running = model.phases.entries
        .firstOrNull { it.value == PhaseState.Running }
        ?.key
    Column(Modifier.fillMaxSize()) {
        Spacer(Modifier.height(8.dp))
        Text(
            stringResource(title),
            Modifier.rise(0),
            style = MaterialTheme.typography.headlineSmall,
            fontWeight = FontWeight.SemiBold,
        )
        AnimatedContent(running, Modifier.padding(top = 6.dp).rise(1), transitionSpec = {
            fadeIn(tween(220)) togetherWith
                fadeOut(tween(160))
        }, label = "now") { now ->
            Text(
                now?.let { stringResource(it.label()) }.orEmpty(),
                style = MaterialTheme.typography.bodyLarge,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        Spacer(Modifier.height(24.dp))
        InstallBar(progress, Modifier.rise(2))
        Row(Modifier.fillMaxWidth().padding(top = 10.dp).rise(3), verticalAlignment = Alignment.CenterVertically) {
            if (progress != null) {
                val shown by animateFloatAsState(progress, tween(600), label = "percent")
                Text(
                    "${(shown * 100).roundToInt()}%",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                )
            }
            Spacer(Modifier.weight(1f))
            if (model.phases[SetupPhase.Copy] == PhaseState.Running) {
                Text(
                    stringResource(Res.string.setup_copied, byteSizeText(copied.first), byteSizeText(copied.second)),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.outline,
                )
            }
        }
        Spacer(Modifier.height(18.dp))
        PhaseChips(model.phases, Modifier.rise(4))
        Spacer(Modifier.weight(1f))
        // The tips make room for the log while it is open.
        var details by rememberSaveable { mutableStateOf(false) }
        if (!removing && !details) Tips(Modifier.padding(bottom = 10.dp).rise(7))
        LogFold(model, details, { details = !details }, Modifier.rise(8))
    }
}

// What the app can do, one at a time, each sliding up over the one before every few seconds while the install runs.
@Composable
private fun Tips(modifier: Modifier = Modifier) {
    val tips =
        listOf(
            Res.string.setup_tip_search,
            Res.string.setup_tip_backup,
            Res.string.setup_tip_theme,
            Res.string.setup_tip_downloads,
        )
    var index by remember { mutableStateOf(0) }
    LaunchedEffect(Unit) {
        while (true) {
            delay(4_500)
            index = (index + 1) % tips.size
        }
    }
    Row(
        modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(softFill())
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(Icons.Outlined.Lightbulb, null, Modifier.size(20.dp), tint = MaterialTheme.colorScheme.primary)
        Text(
            stringResource(Res.string.setup_tip_title),
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.SemiBold,
            color = MaterialTheme.colorScheme.primary,
        )
        AnimatedContent(index, transitionSpec = {
            (slideInVertically { it } + fadeIn()) togetherWith
                (slideOutVertically { -it } + fadeOut())
        }, label = "tip") { shown ->
            Text(stringResource(tips[shown]), style = MaterialTheme.typography.bodyMedium)
        }
    }
}

internal fun SetupPhase.label(): StringResource = when (this) {
    SetupPhase.Unpack -> Res.string.setup_phase_unpack
    SetupPhase.Close -> Res.string.setup_phase_close
    SetupPhase.Old -> Res.string.setup_phase_old
    SetupPhase.Copy -> Res.string.setup_phase_copy
    SetupPhase.Shortcuts -> Res.string.setup_phase_shortcuts
    SetupPhase.Finish -> Res.string.setup_phase_finish
}
