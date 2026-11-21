package com.sumizuri.app.feature.onboarding

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.settings.SettingsRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

// The steps of the first run, in the order they come.
internal enum class OnboardingStep { Welcome, Look, Profile, Library, Reading, Updates, Done }

// The step the person is on, and whether they got there going forward, which sets the side the next page comes in from.
internal data class OnboardingState(val step: OnboardingStep = OnboardingStep.Welcome, val forward: Boolean = true)

// Moves through the first steps, and keeps that they were gone through or skipped, so they show once.
internal class OnboardingViewModel(private val settings: SettingsRepository) : ViewModel() {
    private val mutable = MutableStateFlow(OnboardingState())
    val state: StateFlow<OnboardingState> = mutable

    // The step the person was on when the app closed opens again, unless they already moved on.
    init {
        viewModelScope.launch {
            val saved = settings.text(SettingKey.OnboardingStep).first()
            val step = OnboardingStep.entries.firstOrNull { it.name == saved } ?: return@launch
            mutable.update { if (it.step == OnboardingStep.Welcome) it.copy(step = step) else it }
        }
    }

    private fun keep(step: OnboardingStep) {
        viewModelScope.launch { settings.setText(SettingKey.OnboardingStep, step.name) }
    }

    fun next() {
        mutable.update { now ->
            val steps = OnboardingStep.entries
            now.copy(step = steps[(now.step.ordinal + 1).coerceAtMost(steps.lastIndex)], forward = true)
        }
        keep(mutable.value.step)
    }

    fun back() {
        mutable.update { now ->
            now.copy(step = OnboardingStep.entries[(now.step.ordinal - 1).coerceAtLeast(0)], forward = false)
        }
        keep(mutable.value.step)
    }

    fun finish() {
        viewModelScope.launch { settings.setFlag(SettingKey.OnboardingDone, true) }
    }
}
