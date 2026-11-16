package com.sumizuri.app.navigation

import com.sumizuri.app.data.model.Repo
import com.sumizuri.app.data.text.enumNamed
import com.sumizuri.app.feature.comments.CommentsTarget
import com.sumizuri.app.feature.settings.SettingsTarget
import com.sumizuri.app.feature.settings.controls.ControlsPage
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.source.repo.InstalledSource
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.longOrNull
import kotlinx.serialization.json.put

// The tab and the open pages as JSON text, so they can be saved and brought back. A preview keeps only what it needs to look itself up again.
internal object PlaceJson {
    fun encode(state: NavigationState): String = buildJsonObject {
        put("tab", state.tab.name)
        put(
            "pages",
            buildJsonArray {
                for (page in state.pages) {
                    add(
                        buildJsonObject {
                            when (page) {
                                is Page.Source -> {
                                    put("type", "source")
                                    put("source", page.source.id)
                                }

                                Page.Logs -> put("type", "logs")

                                is Page.RepoSources -> {
                                    put("type", "repo")
                                    put("url", page.repo.url)
                                    put("name", page.repo.name)
                                }

                                is Page.Saved -> {
                                    put("type", "saved")
                                    put("id", page.titleId)
                                }

                                Page.Shelves -> put("type", "shelves")

                                Page.LibraryDisplay -> put("type", "library_display")

                                Page.Settings -> put("type", "settings")

                                Page.Backup -> put("type", "backup")

                                Page.Import -> put("type", "import")

                                Page.Updates -> put("type", "updates")

                                is Page.ThemeEditor -> {
                                    put("type", "theme_editor")
                                    put("id", page.themeId)
                                }

                                is Page.SettingsPage -> {
                                    put("type", "settings_page")
                                    put("name", page.target.name)
                                }

                                Page.History -> put("type", "history")

                                is Page.Controls -> {
                                    put("type", "controls")
                                    put("name", page.page.name)
                                }

                                is Page.Migrate -> {
                                    put("type", "migrate")
                                    put("id", page.titleId)
                                }

                                // The work of moving many titles is kept in the app while it runs, and is not opened again after the app was closed.
                                is Page.Migration -> put("type", "migration")

                                is Page.Reader -> {
                                    put("type", "reader")
                                    put("id", page.chapterId)
                                }

                                is Page.Web -> {
                                    put("type", "web")
                                    put("url", page.url)
                                }

                                is Page.GlobalSearch -> {
                                    put("type", "global_search")
                                    put("query", page.query)
                                }

                                is Page.BlockScript -> {
                                    put("type", "block_script")
                                    put("block", page.blockId)
                                }

                                Page.ArrangeBlocks -> put("type", "arrange_blocks")

                                is Page.ExtensionEditor -> {
                                    put("type", "extension_editor")
                                    page.sourceId?.let { put("source", it) }
                                }

                                is Page.Comments -> {
                                    put("type", "comments")
                                    put("source", page.target.sourceId)
                                    put("url", page.target.url)
                                    put("name", page.target.name)
                                    page.target.chapterUrl?.let { put("chapter", it) }
                                    page.target.chapterName?.let { put("chapterName", it) }
                                }

                                is Page.Preview -> {
                                    put("type", "preview")
                                    put("source", page.source.id)
                                    put("url", page.entry.url)
                                    put("title", page.entry.title)
                                    page.entry.coverUrl?.let { put("cover", it) }
                                }
                            }
                        },
                    )
                }
            },
        )
    }.toString()

    // Reads the saved text. A page that cannot be rebuilt, such as a preview of a source that was removed, is left out.
    fun decode(text: String, installed: List<InstalledSource>): NavigationState? {
        val root = runCatching { Json.parseToJsonElement(text) as? JsonObject }.getOrNull() ?: return null
        val tab = enumNamed<Destination>((root["tab"] as? JsonPrimitive)?.contentOrNull) ?: return null
        val pages = (root["pages"] as? JsonArray).orEmpty().mapNotNull { element ->
            val page = element as? JsonObject ?: return@mapNotNull null
            fun text(name: String) = (page[name] as? JsonPrimitive)?.contentOrNull
            fun number(name: String) = (page[name] as? JsonPrimitive)?.longOrNull
            when (text("type")) {
                "source" -> installed.firstOrNull { it.id == text("source") }?.let { Page.Source(it) }

                "logs" -> Page.Logs

                "repo" -> text("url")?.let { Page.RepoSources(Repo(it, text("name").orEmpty())) }

                "saved" -> number("id")?.let { Page.Saved(it) }

                "shelves" -> Page.Shelves

                "library_display" -> Page.LibraryDisplay

                "settings" -> Page.Settings

                "backup" -> Page.Backup

                "import" -> Page.Import

                "updates" -> Page.Updates

                "theme_editor" -> text("id")?.let { Page.ThemeEditor(it) }

                "settings_page" -> enumNamed<SettingsTarget>(text("name"))?.let { Page.SettingsPage(it) }

                "history" -> Page.History

                "controls" -> enumNamed<ControlsPage>(text("name"))?.let { Page.Controls(it) }

                "migrate" -> number("id")?.let { Page.Migrate(it) }

                "reader" -> number("id")?.let { Page.Reader(it) }

                "web" -> text("url")?.let { Page.Web(it) }

                "global_search" -> Page.GlobalSearch(text("query").orEmpty())

                "block_script" -> text("block")?.let { Page.BlockScript(it) }

                "arrange_blocks" -> Page.ArrangeBlocks

                // The editor of a source that was removed is left out, rather than opened on a new one.
                "extension_editor" -> {
                    val id = text("source")
                    if (id != null && installed.none { it.id == id }) {
                        null
                    } else {
                        Page.ExtensionEditor(id)
                    }
                }

                "comments" -> {
                    val source = text("source") ?: return@mapNotNull null
                    val url = text("url") ?: return@mapNotNull null
                    Page.Comments(
                        CommentsTarget(source, url, text("name").orEmpty(), text("chapter"), text("chapterName")),
                    )
                }

                "preview" -> {
                    val source = installed.firstOrNull { it.id == text("source") } ?: return@mapNotNull null
                    val url = text("url") ?: return@mapNotNull null
                    Page.Preview(
                        source,
                        SourceEntry(url = url, title = text("title").orEmpty(), coverUrl = text("cover")),
                    )
                }

                else -> null
            }
        }
        return NavigationState(tab = tab, pages = pages, restored = true)
    }
}
