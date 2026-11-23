package com.sumizuri.app.feature.tv.library

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.settings.SettingKey
import kotlinx.coroutines.flow.first

// The title with its biggest picture, for the wide art at the top of a TV page. A source gives a small poster that turns soft across a TV, so the background of the show the size of a screen is looked up by its name, while the poster of the source shows until it is found. Nothing is asked when the person turned the season posters off.
@Composable
internal fun rememberWideArt(title: Title): Title {
    val container = LocalAppContainer.current
    val wide by produceState<String?>(null, title.id, title.name) {
        value = null
        if (title.kind != Kind.Anime) return@produceState
        if (!container.settings.flag(SettingKey.AniListSeasonCovers, true).first()) return@produceState
        // A lookup that fails is told in the log and leaves the poster of the source.
        value = container.seasonCovers.wideArt(title.name, keep = title.inLibrary)
    }
    return remember(title, wide) { wide?.let { title.copy(coverUrl = it) } ?: title }
}
