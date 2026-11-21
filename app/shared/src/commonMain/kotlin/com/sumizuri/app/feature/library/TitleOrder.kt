package com.sumizuri.app.feature.library

import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.model.library.Category
import com.sumizuri.app.data.model.library.LibraryEntry
import com.sumizuri.app.data.model.library.LibraryPrefs
import com.sumizuri.app.data.model.library.LibrarySortField
import com.sumizuri.app.data.model.library.SortRule
import com.sumizuri.app.data.model.library.shelf.timesAsked

// What an order needs to know besides the titles: the names of the sources, a number for the random order that stays the same for a while, and the two groups that can be put first.
internal class OrderContext(
    val sourceNames: Map<String, String>,
    val seed: Long,
    val pinFavorites: Boolean,
    val pinUnread: Boolean,
)

// The entries in the order of a rule. Favourites and titles with something unread come first when asked, then the field, then the second field, and the name settles what is still tied.
internal fun List<LibraryEntry>.orderedBy(rule: SortRule, context: OrderContext): List<LibraryEntry> {
    var comparator = Comparator<LibraryEntry> { _, _ -> 0 }
    if (context.pinFavorites) comparator = comparator.thenByDescending { it.title.favorite }
    if (context.pinUnread) comparator = comparator.thenByDescending { it.title.unread > 0 }
    comparator = comparator.then(comparatorOf(rule.sort, rule.ascending, context))
    rule.then?.let { comparator = comparator.then(comparatorOf(it, rule.thenAscending, context)) }
    return sortedWith(comparator.then(comparatorOf(LibrarySortField.Title, true, context)))
}

private fun comparatorOf(field: LibrarySortField, ascending: Boolean, context: OrderContext): Comparator<LibraryEntry> {
    val text = String.CASE_INSENSITIVE_ORDER
    val base: Comparator<LibraryEntry> = when (field) {
        LibrarySortField.Title -> compareBy(text) { it.title.name }
        LibrarySortField.Unread -> compareBy { it.title.unread }
        LibrarySortField.Added -> compareBy { it.title.addedAt }
        LibrarySortField.LastRead -> compareBy { it.lastRead }
        LibrarySortField.LatestChapter -> compareBy { it.latest }
        LibrarySortField.ChapterCount -> compareBy { it.title.chapterCount }
        LibrarySortField.Progress -> compareBy { it.title.readPart ?: 0f }
        LibrarySortField.Status -> compareBy { it.title.status.code }
        LibrarySortField.Source -> compareBy(text) { context.sourceNames[it.title.sourceId] ?: it.title.sourceId }
        LibrarySortField.Author -> compareBy(text) { it.title.author }
        LibrarySortField.Rating -> compareBy { it.title.rating ?: -1.0 }
        LibrarySortField.Kind -> compareBy { it.title.kind.code }
        LibrarySortField.Favorite -> compareBy { it.title.favorite }
        LibrarySortField.Random -> compareBy { scramble(it.title.id xor context.seed) }
    }
    return if (ascending) base else base.reversed()
}

// A number that looks unrelated to the one given, the same each time, so the random order only changes with the seed.
private fun scramble(value: Long): Long {
    var mixed = value * -7046029254386353131L
    mixed = mixed xor (mixed ushr 32)
    mixed *= -4658895280553007687L
    return mixed xor (mixed ushr 29)
}

// The name an order of a kind is kept under.
internal fun kindRuleKey(kind: Kind): String = "kind.${kind.code}"

// The order that applies where the person is. The open shelf, or the tab of all the titles or of the titles on no shelf, goes first when it has an order of its own, then the open kind, and last the default order.
internal fun effectiveRule(prefs: LibraryPrefs, kind: Kind?, shelf: Category?): SortRule {
    val place = when (prefs.category) {
        null -> prefs.rules["all"]
        UncategorizedShelf -> prefs.rules["none"]
        else -> shelf?.rule
    }
    return place ?: kind?.let { prefs.rules[kindRuleKey(it)] } ?: prefs.defaultRule
}

// Every field that any order of the library reads, so the times the library has to look up are only the ones that some order needs.
internal fun fieldsInUse(prefs: LibraryPrefs, shelves: List<Category>): Set<LibrarySortField> = buildSet {
    addAll(prefs.defaultRule.fields)
    prefs.rules.values.forEach { addAll(it.fields) }
    shelves.forEach { shelf -> shelf.rule?.let { addAll(it.fields) } }
    // A smart shelf that asks when a title was read or updated needs those times too.
    addAll(shelves.timesAsked())
}
