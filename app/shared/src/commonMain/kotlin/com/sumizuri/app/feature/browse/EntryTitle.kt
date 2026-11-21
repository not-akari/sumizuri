package com.sumizuri.app.feature.browse

import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.text.statusFromText
import com.sumizuri.app.source.model.SourceEntry

// A source entry shaped like a title, so the shared cover pieces can draw it. It has no row in the database.
fun SourceEntry.asTitle(kind: Kind, sourceId: String = ""): Title = Title(
    id = 0,
    sourceId = sourceId,
    name = title,
    kind = kind,
    coverUrl = coverUrl,
    unread = 0,
    status = statusFromText(status),
    summary = description.orEmpty(),
    author = author.orEmpty(),
    genres = genres,
    webUrl = webUrl,
    inLibrary = false,
)
