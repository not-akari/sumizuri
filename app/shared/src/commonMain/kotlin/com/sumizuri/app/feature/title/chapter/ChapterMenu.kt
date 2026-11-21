package com.sumizuri.app.feature.title.chapter

import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import com.sumizuri.app.data.model.ChapterSort
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.chapter_sort_date
import com.sumizuri.app.shared.resources.chapter_sort_number
import com.sumizuri.app.shared.resources.chapter_sort_source
import org.jetbrains.compose.resources.StringResource

// The name of each order, here and in the settings.
internal fun sortLabel(sort: ChapterSort): StringResource = when (sort) {
    ChapterSort.Source -> Res.string.chapter_sort_source
    ChapterSort.Number -> Res.string.chapter_sort_number
    ChapterSort.Date -> Res.string.chapter_sort_date
}
