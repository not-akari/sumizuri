package com.sumizuri.app.feature.migration

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.data.migration.MigrationSession
import com.sumizuri.app.data.migration.MigrationState
import com.sumizuri.app.data.migration.MigrationStatus
import com.sumizuri.app.data.model.library.Category
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.mig_rules_hint
import com.sumizuri.app.shared.resources.mig_subtitle
import com.sumizuri.app.shared.resources.mig_tab_rules
import com.sumizuri.app.shared.resources.mig_title
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.kit.page.ReadableColumn
import com.sumizuri.app.ui.kit.step.StepTrack
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import org.jetbrains.compose.resources.stringResource

// The page for moving many titles at once, as three steps: pick the titles, pick the sources, then search and review. The rules open from the gear at the top, and the bar under the steps moves on.
@Composable
internal fun MigrationScreen(
    state: MigrationState,
    shelves: List<Category>,
    session: MigrationSession,
    onBack: () -> Unit,
    onOpenTitle: (Long) -> Unit,
) {
    var step by rememberSaveable { mutableStateOf(MigrationStep.Titles) }
    var rules by rememberSaveable { mutableStateOf(false) }
    var placed by rememberSaveable { mutableStateOf(false) }
    // Work that is running or has results when the page opens starts on the last step.
    LaunchedEffect(state.loaded) {
        if (state.loaded && !placed) {
            placed = true
            if (state.busy || state.items.any { it.included && it.status != MigrationStatus.Queued }) {
                step = MigrationStep.Search
            }
        }
    }
    NavigationBackHandler(
        rememberNavigationEventState(NavigationEventInfo.None),
        isBackEnabled = rules || step != MigrationStep.Titles,
    ) {
        if (rules) rules = false else step = MigrationStep.entries[step.ordinal - 1]
    }
    val ms = motionMs(AppMotion.Page)
    ReadableColumn {
        Column(Modifier.fillMaxSize()) {
            PageTopBar(
                stringResource(if (rules) Res.string.mig_tab_rules else Res.string.mig_title),
                subtitle = stringResource(if (rules) Res.string.mig_rules_hint else Res.string.mig_subtitle),
                onBack = if (rules) ({ rules = false }) else onBack,
                actions = {
                    if (!rules) {
                        IconButton(
                            { rules = true },
                        ) { Icon(Icons.Outlined.Tune, stringResource(Res.string.mig_tab_rules)) }
                    }
                },
            )
            AnimatedContent(
                rules,
                Modifier.weight(1f).fillMaxWidth(),
                transitionSpec = { fadeIn(tween(ms)) togetherWith fadeOut(tween(ms / 2)) },
                label = "rules",
            ) { showRules ->
                if (showRules) {
                    MigrationRulesTab(state, session)
                } else {
                    Column(Modifier.fillMaxSize()) {
                        StepTrack(
                            MigrationStep.entries.map { stringResource(it.label) },
                            step.ordinal,
                            Modifier.padding(horizontal = PageGutter),
                        ) { step = MigrationStep.entries[it] }
                        AnimatedContent(
                            step,
                            Modifier.weight(1f).fillMaxWidth(),
                            transitionSpec = {
                                val forward = targetState.ordinal > initialState.ordinal
                                (
                                    slideInHorizontally(tween(ms)) { if (forward) it / 5 else -it / 5 } +
                                        fadeIn(tween(ms))
                                    ) togetherWith
                                    (
                                        slideOutHorizontally(tween(ms)) { if (forward) -it / 6 else it / 6 } +
                                            fadeOut(tween(ms / 2))
                                        )
                            },
                            label = "step",
                        ) { shown ->
                            when {
                                !state.loaded -> InkCircularProgressIndicator(Modifier.padding(24.dp))
                                shown == MigrationStep.Titles -> MigrationTitlesTab(state, shelves, session)
                                shown == MigrationStep.Sources -> MigrationSourcesTab(state, session)
                                else -> MigrationResultsTab(state, session, onOpenTitle)
                            }
                        }
                        MigrationBar(state, session, step) { step = it }
                    }
                }
            }
        }
    }
}
