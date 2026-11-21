package com.sumizuri.app.data.library

// A chapter its site holds back for now, found from the note a source puts in its name, such as Chapter 70 (Locked, unlocks in 5h 8m). The name is the one without the note, and left is how long the site said was left, as the site wrote it.
class ChapterLock(val name: String?, val left: String?)

// The words of a note that say a chapter is held back.
private val LockWords = Regex("\\b(locked|paid|premium|early access|coins?)\\b", RegexOption.IGNORE_CASE)

// A note in round or square brackets.
private val Notes = Regex("[(\\[]([^)\\]]*)[)\\]]")

// How long is left, such as unlocks in 5h 8m or free in 2d.
private val LeftIn = Regex("(?:unlocks?|free|available)\\s+in\\s+(\\d[\\dwdhms ]*[wdhms])\\b", RegexOption.IGNORE_CASE)

private const val LockMark = "🔒"
private val Spaces = Regex("\\s{2,}")

// The lock of a chapter, or null when its name says nothing of one.
fun chapterLock(name: String?): ChapterLock? {
    if (name.isNullOrBlank()) return null
    val note = Notes.findAll(name).firstOrNull { LockWords.containsMatchIn(it.groupValues[1]) }
    if (note == null && !name.contains(LockMark)) return null
    // The time left is read from the note first, and else from the rest of the name, where it is taken out too.
    val outside = if (note?.let { LeftIn.containsMatchIn(it.value) } == true) null else LeftIn.find(name)
    val left = (note?.let { LeftIn.find(it.value) } ?: outside)?.groupValues?.get(1)?.trim()
    val bare = (if (note != null) name.removeRange(note.range) else name)
        .let { rest -> outside?.value?.let { rest.replace(it, " ") } ?: rest }
        .replace(LockMark, " ")
        .replace(Spaces, " ")
        .trim()
        .trimEnd('-', ':', '|')
        .trim()
    return ChapterLock(bare.ifEmpty { null }, left)
}
