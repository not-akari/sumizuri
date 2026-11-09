package com.sumizuri.app.feature.reader.translate

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.net.SiteKinds
import com.sumizuri.app.feature.reader.ReaderPage
import com.sumizuri.app.feature.reader.ReaderState
import io.ktor.client.HttpClient
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.request.forms.submitForm
import io.ktor.client.statement.bodyAsText
import io.ktor.http.HttpStatusCode
import io.ktor.http.encodeURLParameter
import io.ktor.http.parameters
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.delay
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonPrimitive

// The free service of Google Translate that the translate pages of browsers use. It finds the language of the text by itself, and the language to translate to goes at the end.
private const val TranslateAddress = "https://translate.googleapis.com/translate_a/single?client=gtx&sl=auto&dt=t&tl="

// The same translator behind the address the Chrome extension uses, with limits of its own, for when the first one does not answer. It answers with the whole text and its language.
private const val SpareAddress = "https://clients5.google.com/translate_a/t?client=dict-chrome-ex&sl=auto&tl="

// The two addresses in order, each with how its answer is read: the first cuts the text in sentences, each with its translation first, and the spare gives the whole translation first.
private val Addresses: List<Pair<String, (JsonArray) -> String>> = listOf(
    TranslateAddress to { answer ->
        answer.first().jsonArray.joinToString("") {
            it.jsonArray
                .firstOrNull()
                ?.jsonPrimitive
                ?.contentOrNull
                .orEmpty()
        }
    },
    SpareAddress to { answer ->
        answer
            .first()
            .jsonArray
            .first()
            .jsonPrimitive.content
    },
)

// How long to wait before asking again once both addresses failed.
private const val RetryAfterMs = 1_500L

// How many paragraphs are kept translated while the app runs, all dropped at once when full, so a long reading does not fill the memory.
private const val KeepAtMost = 5_000

// How long the service has to answer one batch, and how many letters go in one batch, below what it takes in one call.
private const val AnswerWithinMs = 20_000L
private const val BatchLetters = 4_000

// The paragraphs of a batch are sent apart by a blank line, and the answer is cut back at its blank lines.
private const val Gap = "\n\n"
private val BlankLine = Regex("\\n\\s*\\n")

// Where the translation of a chapter is: off, being made, shown, or stopped because the service did not answer.
enum class TranslateStatus { Off, Working, On, Failed }

// What outlives one chapter while the app runs: whether the translation was left on, so the next chapter opens translated too, and the paragraphs translated so far by their text, so each one is asked for once.
private object Kept {
    var on = false
    var language = ""
    val done = HashMap<String, String>()
}

// Puts the words of a novel into the language of the app. Paragraphs go to the service together in batches.
class NovelTranslator : AutoCloseable {
    private val http = HttpClient { install(HttpTimeout) { requestTimeoutMillis = AnswerWithinMs } }

    // The translator takes the way set for novels, as it carries their words.
    init {
        SiteKinds.mark(TranslateAddress, Kind.Novel)
        SiteKinds.mark(SpareAddress, Kind.Novel)
    }

    var status by mutableStateOf(if (Kept.on) TranslateStatus.Working else TranslateStatus.Off)
        private set

    // The translation of each paragraph that has one, by the text of the paragraph.
    var translations by mutableStateOf<Map<String, String>>(emptyMap())
        private set

    // Whether translated words are asked for, which they are while they are being made and once they are shown.
    val active: Boolean get() = status == TranslateStatus.Working || status == TranslateStatus.On

    // Turns the translation on, or off when it is on. Off shows the words as the source gave them.
    fun toggle() {
        status = if (active) TranslateStatus.Off else TranslateStatus.Working
        Kept.on = active
    }

    // Translates the paragraphs of the pages that have no translation yet, to the language with the code given, such as es.
    suspend fun translate(pages: List<ReaderPage>, language: String) {
        // Translations to another language are no use once the app speaks a new one.
        if (Kept.language != language || Kept.done.size > KeepAtMost) {
            Kept.done.clear()
            Kept.language = language
        }
        val missing = pages.mapNotNull { it.text }.filter { it.isNotBlank() && it !in Kept.done }.distinct()
        translations = Kept.done.toMap()
        // A batch that fails leaves its paragraphs as the source gave them while the others go on, and the next pass asks for them again.
        var failed = 0
        for (batch in batchesOf(missing)) {
            try {
                val answer = ask(batch.joinToString(Gap), language)
                val parts = answer.split(BlankLine).map { it.trim() }
                // When the paragraphs did not come back one for one, the batch stays as the source gave it, rather than asking for each paragraph alone and running into the limits of the service.
                if (parts.size != batch.size) error("The translation came back cut differently")
                batch.zip(parts).forEach { (text, translated) -> Kept.done[text] = translated }
                translations = Kept.done.toMap()
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (_: Exception) {
                failed++
            }
        }
        // Failed only when nothing at all came back.
        status = if (failed > 0 && translations.isEmpty()) TranslateStatus.Failed else TranslateStatus.On
    }

    // The paragraphs in groups that each stay under the size of one call. A paragraph longer than that goes alone.
    private fun batchesOf(texts: List<String>): List<List<String>> {
        val batches = mutableListOf<MutableList<String>>()
        var letters = 0
        for (text in texts) {
            if (batches.isEmpty() || letters + text.length > BatchLetters) {
                batches += mutableListOf<String>()
                letters = 0
            }
            batches.last() += text
            letters += text.length + Gap.length
        }
        return batches
    }

    // Asks the first address, then the spare one, and both once more after a short wait.
    private suspend fun ask(text: String, language: String): String {
        repeat(2) { round ->
            if (round > 0) delay(RetryAfterMs)
            for ((address, read) in Addresses) {
                runCatching {
                    return askAt(
                        address,
                        read,
                        text,
                        language,
                    )
                }.onFailure { if (it is CancellationException) throw it }
            }
        }
        error("The translate service did not answer")
    }

    private suspend fun askAt(address: String, read: (JsonArray) -> String, text: String, language: String): String {
        val response = http.submitForm(address + language.encodeURLParameter(), parameters { append("q", text) })
        if (response.status != HttpStatusCode.OK) error("The translate service answered ${response.status}")
        return read(Json.parseToJsonElement(response.bodyAsText()).jsonArray)
    }

    override fun close() = http.close()
}

// The state with the words of each paragraph that has a translation put in their place.
fun ReaderState.translatedWith(translations: Map<String, String>): ReaderState {
    if (translations.isEmpty()) return this
    return copy(pages = pages.map { page -> page.text?.let(translations::get)?.let { page.copy(text = it) } ?: page })
}
