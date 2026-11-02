package com.sumizuri.app.feature.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.settings.SettingsRepository
import com.sumizuri.app.data.text.enumNamed
import com.sumizuri.app.navigation.bar.NavLabels
import com.sumizuri.app.navigation.bar.NavStyle
import com.sumizuri.app.ui.language.AppLanguage
import com.sumizuri.app.ui.motion.PageMotion
import com.sumizuri.app.ui.theme.ThemeMode
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

class SettingsViewModel(private val repository: SettingsRepository) : ViewModel() {
    // Which settings of the look have been read, one bit each, so the first screen waits for them and never draws in the default look first.
    private val lookParts = MutableStateFlow(0)

    private fun <T> Flow<T>.lookPart(bit: Int): Flow<T> = onEach { lookParts.update { it or bit } }

    val lookRead: StateFlow<Boolean> =
        lookParts.map { it == LookPartsAll }.stateIn(viewModelScope, SharingStarted.Eagerly, false)

    val themeMode: StateFlow<ThemeMode> =
        repository.themeMode.lookPart(1).stateIn(viewModelScope, SharingStarted.Eagerly, ThemeMode.System)

    val compactLists: StateFlow<Boolean> = repository
        .flag(
            SettingKey.CompactLists,
            false,
        ).stateIn(viewModelScope, SharingStarted.Eagerly, false)

    val reduceMotion: StateFlow<Boolean> = repository
        .flag(
            SettingKey.ReduceMotion,
            false,
        ).stateIn(viewModelScope, SharingStarted.Eagerly, false)

    val navStyle: StateFlow<NavStyle> = repository
        .text(SettingKey.NavStyle)
        .map { saved -> enumNamed<NavStyle>(saved) ?: NavStyle.Auto }
        .stateIn(viewModelScope, SharingStarted.Eagerly, NavStyle.Auto)

    val oled: StateFlow<Boolean> = repository
        .flag(
            SettingKey.Oled,
            false,
        ).lookPart(2)
        .stateIn(viewModelScope, SharingStarted.Eagerly, false)

    val oledGlow: StateFlow<Boolean> = repository
        .flag(
            SettingKey.OledGlow,
            false,
        ).lookPart(4)
        .stateIn(viewModelScope, SharingStarted.Eagerly, false)

    val navLabels: StateFlow<NavLabels> = repository
        .text(SettingKey.NavLabels)
        .map { saved -> enumNamed<NavLabels>(saved) ?: NavLabels.Always }
        .stateIn(viewModelScope, SharingStarted.Eagerly, NavLabels.Always)

    val navSwipe: StateFlow<Boolean> = repository
        .flag(
            SettingKey.NavSwipe,
            false,
        ).stateIn(viewModelScope, SharingStarted.Eagerly, false)

    val pageMotion: StateFlow<PageMotion> = repository
        .text(SettingKey.PageMotion)
        .map { saved -> enumNamed<PageMotion>(saved) ?: PageMotion.Smooth }
        .stateIn(viewModelScope, SharingStarted.Eagerly, PageMotion.Smooth)

    val stagger: StateFlow<Boolean> = repository
        .flag(
            SettingKey.Stagger,
            true,
        ).stateIn(viewModelScope, SharingStarted.Eagerly, true)

    val language: StateFlow<AppLanguage> = repository
        .text(SettingKey.Language)
        .map { saved -> AppLanguage.fromSaved(saved) }
        .stateIn(viewModelScope, SharingStarted.Eagerly, AppLanguage.System)

    val updateHours: StateFlow<Int> = repository
        .number(
            SettingKey.UpdateHours,
            SettingKey.DefaultUpdateHours,
        ).stateIn(viewModelScope, SharingStarted.Eagerly, SettingKey.DefaultUpdateHours)

    val skipCompleted: StateFlow<Boolean> = repository
        .flag(
            SettingKey.UpdateSkipCompleted,
            false,
        ).stateIn(viewModelScope, SharingStarted.Eagerly, false)

    val skipNotStarted: StateFlow<Boolean> = repository
        .flag(
            SettingKey.UpdateSkipNotStarted,
            false,
        ).stateIn(viewModelScope, SharingStarted.Eagerly, false)

    fun onUpdateHours(hours: Int) {
        viewModelScope.launch { repository.setNumber(SettingKey.UpdateHours, hours) }
    }

    fun onSkipCompleted(on: Boolean) {
        viewModelScope.launch { repository.setFlag(SettingKey.UpdateSkipCompleted, on) }
    }

    fun onSkipNotStarted(on: Boolean) {
        viewModelScope.launch { repository.setFlag(SettingKey.UpdateSkipNotStarted, on) }
    }

    val imageDiskMb: StateFlow<Int> = repository
        .number(
            SettingKey.ImageDiskMb,
            SettingKey.DefaultImageDiskMb,
        ).stateIn(viewModelScope, SharingStarted.Eagerly, SettingKey.DefaultImageDiskMb)

    val imageMemoryPercent: StateFlow<Int> = repository
        .number(
            SettingKey.ImageMemoryPercent,
            SettingKey.DefaultImageMemoryPercent,
        ).stateIn(viewModelScope, SharingStarted.Eagerly, SettingKey.DefaultImageMemoryPercent)

    val pageMemoryMb: StateFlow<Int> = repository
        .number(
            SettingKey.PageMemoryMb,
            SettingKey.DefaultPageMemoryMb,
        ).stateIn(viewModelScope, SharingStarted.Eagerly, SettingKey.DefaultPageMemoryMb)

    val pageKeepMinutes: StateFlow<Int> = repository
        .number(
            SettingKey.PageKeepMinutes,
            SettingKey.DefaultPageKeepMinutes,
        ).stateIn(viewModelScope, SharingStarted.Eagerly, SettingKey.DefaultPageKeepMinutes)

    fun onImageDiskMb(value: Int) {
        viewModelScope.launch { repository.setNumber(SettingKey.ImageDiskMb, value) }
    }

    fun onImageMemoryPercent(value: Int) {
        viewModelScope.launch { repository.setNumber(SettingKey.ImageMemoryPercent, value) }
    }

    val aniListSeasonCovers: StateFlow<Boolean> = repository
        .flag(
            SettingKey.AniListSeasonCovers,
            true,
        ).stateIn(viewModelScope, SharingStarted.Eagerly, true)

    fun onAniListSeasonCovers(on: Boolean) {
        viewModelScope.launch { repository.setFlag(SettingKey.AniListSeasonCovers, on) }
    }

    fun onPageMemoryMb(value: Int) {
        viewModelScope.launch { repository.setNumber(SettingKey.PageMemoryMb, value) }
    }

    fun onPageKeepMinutes(value: Int) {
        viewModelScope.launch { repository.setNumber(SettingKey.PageKeepMinutes, value) }
    }

    fun onNavStyle(style: NavStyle) {
        viewModelScope.launch { repository.setText(SettingKey.NavStyle, style.name) }
    }

    fun onOled(on: Boolean) {
        viewModelScope.launch { repository.setFlag(SettingKey.Oled, on) }
    }

    fun onOledGlow(on: Boolean) {
        viewModelScope.launch { repository.setFlag(SettingKey.OledGlow, on) }
    }

    fun onNavLabels(labels: NavLabels) {
        viewModelScope.launch { repository.setText(SettingKey.NavLabels, labels.name) }
    }

    fun onNavSwipe(on: Boolean) {
        viewModelScope.launch { repository.setFlag(SettingKey.NavSwipe, on) }
    }

    fun onPageMotion(motion: PageMotion) {
        viewModelScope.launch { repository.setText(SettingKey.PageMotion, motion.name) }
    }

    fun onStagger(on: Boolean) {
        viewModelScope.launch { repository.setFlag(SettingKey.Stagger, on) }
    }

    fun onLanguage(language: AppLanguage) {
        viewModelScope.launch { repository.setText(SettingKey.Language, language.code ?: "System") }
    }

    fun onCompactLists(on: Boolean) {
        viewModelScope.launch { repository.setFlag(SettingKey.CompactLists, on) }
    }

    fun onReduceMotion(on: Boolean) {
        viewModelScope.launch { repository.setFlag(SettingKey.ReduceMotion, on) }
    }

    fun onThemeMode(mode: ThemeMode) {
        viewModelScope.launch { repository.setThemeMode(mode) }
    }
}

// The bits of the dark mode, the black page and its glow, all read.
private const val LookPartsAll = 7
