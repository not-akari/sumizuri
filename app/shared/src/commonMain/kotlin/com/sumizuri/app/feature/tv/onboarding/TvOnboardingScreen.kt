package com.sumizuri.app.feature.tv.onboarding

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewModelScope
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigationevent.NavigationEventInfo
import androidx.navigationevent.compose.NavigationBackHandler
import androidx.navigationevent.compose.rememberNavigationEventState
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.profile.LocalProfiles
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.settings.SettingsRepository
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.feature.sync.SyncRoute
import com.sumizuri.app.feature.tv.pair.TvPhonePair
import com.sumizuri.app.ui.theme.background.ambientBackground
import com.sumizuri.app.ui.tv.TvOverlay
import com.sumizuri.app.ui.tv.hiddenUnder
import com.sumizuri.app.ui.tv.keepsFocus
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

// The steps of the first run on a TV, in the order they come.
internal enum class TvStep { Welcome, Profile, Look, Library, Watching, Done }

// The step the person is on, and whether they got there going forward, which sets the side the next one comes in from.
internal data class TvOnboardingState(val step: TvStep = TvStep.Welcome, val forward: Boolean = true)

// The saved step of a TV starts with this, so it never mixes with the steps of a phone or a computer.
private const val SavedMark = "tv:"

// Moves through the steps on a TV, and keeps the step and the end the same way as the first run anywhere else.
internal class TvOnboardingModel(private val settings: SettingsRepository) : ViewModel() {
    private val mutable = MutableStateFlow(TvOnboardingState())
    val state: StateFlow<TvOnboardingState> = mutable

    init {
        viewModelScope.launch {
            val saved = settings.text(SettingKey.OnboardingStep).first()?.removePrefix(SavedMark)
            val step = TvStep.entries.firstOrNull { it.name == saved } ?: return@launch
            mutable.update { if (it.step == TvStep.Welcome) it.copy(step = step) else it }
        }
    }

    private fun move(by: Int) {
        mutable.update { now ->
            now.copy(
                step = TvStep.entries[(now.step.ordinal + by).coerceIn(0, TvStep.entries.lastIndex)],
                forward =
                by > 0,
            )
        }
        viewModelScope.launch { settings.setText(SettingKey.OnboardingStep, SavedMark + mutable.value.step.name) }
    }

    fun next() = move(1)

    fun back() = move(-1)

    fun finish() {
        viewModelScope.launch { settings.setFlag(SettingKey.OnboardingDone, true) }
    }
}

// The first steps on a TV, over the whole app: a welcome, the name of the profile, where the library comes from, how videos start, and the end. Everything is reached with the arrows of the remote, and back goes a step back.
@Composable
internal fun TvOnboardingScreen(onOpenSettings: (SettingsTarget) -> Unit, modifier: Modifier = Modifier) {
    val container = LocalAppContainer.current
    val model = viewModel { TvOnboardingModel(container.settings) }
    val state by model.state.collectAsStateWithLifecycle()
    var syncing by rememberSaveable { mutableStateOf(false) }
    var phone by rememberSaveable { mutableStateOf(false) }
    val account by LocalProfiles.current.syncAccounts.account
        .collectAsStateWithLifecycle()
    NavigationBackHandler(
        rememberNavigationEventState(NavigationEventInfo.None),
        isBackEnabled = !syncing && !phone && state.step != TvStep.Welcome,
    ) { model.back() }
    Box(
        // The first steps keep the remote, so the library under them never takes it while it loads.
        modifier
            .fillMaxSize()
            .ambientBackground()
            .pointerInput(Unit) {
                awaitPointerEventScope { while (true) awaitPointerEvent() }
            }.keepsFocus(),
    ) {
        AnimatedContent(
            state,
            Modifier.fillMaxSize().hiddenUnder(syncing || phone),
            transitionSpec = {
                val forward = targetState.forward
                val enter =
                    slideInHorizontally(tween(460, easing = FastOutSlowInEasing)) { if (forward) it / 5 else -it / 5 } +
                        fadeIn(tween(340, delayMillis = 80))
                val exit =
                    slideOutHorizontally(
                        tween(320, easing = FastOutSlowInEasing),
                    ) { if (forward) -it / 6 else it / 6 } +
                        fadeOut(tween(180))
                enter togetherWith exit
            },
            contentKey = { it.step },
            label = "tv step",
        ) { shown ->
            when (shown.step) {
                TvStep.Welcome -> WelcomeStep(model::next)

                TvStep.Profile -> ProfileStep(shown.step, model::next)

                TvStep.Look -> LookStep(shown.step, model::next)

                TvStep.Library -> LibraryStep(
                    shown.step,
                    account != null,
                    onSync = { syncing = true },
                    onPhone = { phone = true },
                    onNext = model::next,
                )

                TvStep.Watching -> WatchingStep(shown.step, model::next)

                TvStep.Done -> DoneStep(model::finish)
            }
        }
        // What a phone sent goes on to the next step once it was taken in.
        if (phone) {
            NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = true) {
                phone =
                    false
            }
            TvOverlay {
                TvPhonePair { done ->
                    phone = false
                    if (done) model.next()
                }
            }
        }
        if (syncing) {
            NavigationBackHandler(rememberNavigationEventState(NavigationEventInfo.None), isBackEnabled = true) {
                syncing =
                    false
            }
            TvOverlay(Modifier.padding(horizontal = 48.dp, vertical = 24.dp)) {
                // Leaving the sync signed in goes on to the next step, and leaving it without stays here.
                SyncRoute(onBack = {
                    syncing = false
                    if (account != null) model.next()
                }) { target ->
                    model.finish()
                    onOpenSettings(target)
                }
            }
        }
    }
}

// A step in the middle: the dots of the steps, its name and a line about it on the left, and what is chosen on the right.
@Composable
internal fun StepFrame(step: TvStep, title: String, text: String, content: @Composable ColumnScope.() -> Unit) {
    Row(Modifier.fillMaxSize().padding(horizontal = 72.dp, vertical = 40.dp)) {
        Column(Modifier.weight(0.9f).fillMaxHeight()) {
            StepDots(step)
            Spacer(Modifier.weight(1f))
            Text(title, fontSize = 36.sp, fontWeight = FontWeight.SemiBold, lineHeight = 42.sp)
            Text(
                text,
                Modifier.padding(top = 14.dp).widthIn(max = 380.dp),
                fontSize = 18.sp,
                lineHeight = 26.sp,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
            )
            Spacer(Modifier.weight(1.3f))
        }
        Spacer(Modifier.width(56.dp))
        Column(
            Modifier.weight(1.1f).fillMaxHeight(),
            verticalArrangement = Arrangement.spacedBy(12.dp, Alignment.CenterVertically),
            content = content,
        )
    }
}

// A step at either end, with everything in the middle of the screen.
@Composable
internal fun EndFrame(title: String, text: String, content: @Composable ColumnScope.() -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(48.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
    ) {
        Text(title, fontSize = 44.sp, fontWeight = FontWeight.SemiBold, textAlign = TextAlign.Center)
        Text(
            text,
            Modifier.padding(top = 16.dp, bottom = 36.dp).widthIn(max = 560.dp),
            fontSize = 19.sp,
            lineHeight = 28.sp,
            textAlign = TextAlign.Center,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        content()
    }
}

// One dot for each step in the middle, the one the person is on drawn out, and the ones behind in the accent.
@Composable
internal fun StepDots(step: TvStep) {
    val middle = TvStep.entries.drop(1).dropLast(1)
    Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
        for (each in middle) {
            val here = each == step
            val width by animateDpAsState(if (here) 28.dp else 9.dp, tween(320), label = "dot")
            val colors = MaterialTheme.colorScheme
            Box(
                Modifier
                    .height(9.dp)
                    .width(width)
                    .background(
                        if (here ||
                            each.ordinal < step.ordinal
                        ) {
                            colors.primary
                        } else {
                            colors.onSurface.copy(alpha = 0.2f)
                        },
                        RoundedCornerShape(50),
                    ),
            )
        }
        Spacer(Modifier.size(0.dp))
    }
}
