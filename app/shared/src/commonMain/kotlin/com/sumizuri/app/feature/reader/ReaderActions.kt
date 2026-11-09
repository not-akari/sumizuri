package com.sumizuri.app.feature.reader

import com.sumizuri.app.data.model.reader.ReaderMode
import com.sumizuri.app.data.model.reader.ReaderSettings
import com.sumizuri.app.feature.comments.CommentsTarget

// Everything the reader can ask of the model, so the screen is given one thing and not a dozen.
class ReaderActions(
    val onProgress: (shown: Int, reached: Int, count: Int) -> Unit,
    val onRetry: () -> Unit,
    val onSolve: () -> Unit,
    val onOpenChapter: (Long) -> Unit,
    val onBack: () -> Unit,
    val onAspects: (List<Double>) -> Unit,
    val onMode: (ReaderMode) -> Unit,
    val onDefaultMode: (ReaderMode) -> Unit,
    val onSettings: (ReaderSettings) -> Unit,
    val onBookmark: () -> Unit,
    val onSetCover: (String) -> Unit,
    val onActive: (Int) -> Unit,
    val onNearEnd: () -> Unit,
    // Opens the comments of a chapter.
    val onComments: (CommentsTarget) -> Unit,
)
