package com.sumizuri.app.feature.migration

import com.sumizuri.app.data.migration.ChapterRule
import com.sumizuri.app.data.migration.MigrationStatus
import com.sumizuri.app.data.migration.Strictness
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.mig_chapters_any
import com.sumizuri.app.shared.resources.mig_chapters_as_many
import com.sumizuri.app.shared.resources.mig_chapters_as_new
import com.sumizuri.app.shared.resources.mig_chapters_progress
import com.sumizuri.app.shared.resources.mig_status_failed
import com.sumizuri.app.shared.resources.mig_status_found
import com.sumizuri.app.shared.resources.mig_status_moved
import com.sumizuri.app.shared.resources.mig_status_not_found
import com.sumizuri.app.shared.resources.mig_status_queued
import com.sumizuri.app.shared.resources.mig_status_review
import com.sumizuri.app.shared.resources.mig_status_searching
import com.sumizuri.app.shared.resources.mig_step_search
import com.sumizuri.app.shared.resources.mig_strict_balanced
import com.sumizuri.app.shared.resources.mig_strict_loose
import com.sumizuri.app.shared.resources.mig_strict_strict
import com.sumizuri.app.shared.resources.mig_tab_sources
import com.sumizuri.app.shared.resources.mig_tab_titles
import org.jetbrains.compose.resources.StringResource

// The three steps of the page: which titles, which sources, then the search and what it found.
internal enum class MigrationStep(val label: StringResource) {
    Titles(Res.string.mig_tab_titles),
    Sources(Res.string.mig_tab_sources),
    Search(Res.string.mig_step_search),
}

// The word for where a title is in the work.
internal fun MigrationStatus.label(): StringResource = when (this) {
    MigrationStatus.Queued -> Res.string.mig_status_queued
    MigrationStatus.Searching -> Res.string.mig_status_searching
    MigrationStatus.Found -> Res.string.mig_status_found
    MigrationStatus.Review -> Res.string.mig_status_review
    MigrationStatus.NotFound -> Res.string.mig_status_not_found
    MigrationStatus.Moved -> Res.string.mig_status_moved
    MigrationStatus.Failed -> Res.string.mig_status_failed
}

// The words for how close a name must be, and for what the chapters of a match must look like.
internal fun strictnessLabel(strictness: Strictness) = when (strictness) {
    Strictness.Strict -> Res.string.mig_strict_strict
    Strictness.Balanced -> Res.string.mig_strict_balanced
    Strictness.Loose -> Res.string.mig_strict_loose
}

internal fun chapterRuleLabel(rule: ChapterRule) = when (rule) {
    ChapterRule.Any -> Res.string.mig_chapters_any
    ChapterRule.AtLeastAsMany -> Res.string.mig_chapters_as_many
    ChapterRule.AtLeastAsNew -> Res.string.mig_chapters_as_new
    ChapterRule.CoversProgress -> Res.string.mig_chapters_progress
}
