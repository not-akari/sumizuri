package com.sumizuri.app.feature.migration

import androidx.compose.runtime.Composable
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.migration.ChapterRule
import com.sumizuri.app.data.migration.MigrationRules
import com.sumizuri.app.data.migration.MigrationSession
import com.sumizuri.app.data.migration.MigrationState
import com.sumizuri.app.data.migration.Strictness
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.mig_group_chapters
import com.sumizuri.app.shared.resources.mig_group_matching
import com.sumizuri.app.shared.resources.mig_group_moving
import com.sumizuri.app.shared.resources.mig_group_pace
import com.sumizuri.app.shared.resources.mig_group_searching
import com.sumizuri.app.shared.resources.mig_rule_allow_merge
import com.sumizuri.app.shared.resources.mig_rule_allow_merge_hint
import com.sumizuri.app.shared.resources.mig_rule_auto_accept
import com.sumizuri.app.shared.resources.mig_rule_auto_accept_hint
import com.sumizuri.app.shared.resources.mig_rule_chapters
import com.sumizuri.app.shared.resources.mig_rule_compare_all
import com.sumizuri.app.shared.resources.mig_rule_compare_all_hint
import com.sumizuri.app.shared.resources.mig_rule_delay
import com.sumizuri.app.shared.resources.mig_rule_give_up
import com.sumizuri.app.shared.resources.mig_rule_keep_favorite
import com.sumizuri.app.shared.resources.mig_rule_keep_old
import com.sumizuri.app.shared.resources.mig_rule_keep_old_hint
import com.sumizuri.app.shared.resources.mig_rule_keep_shelves
import com.sumizuri.app.shared.resources.mig_rule_looks_at
import com.sumizuri.app.shared.resources.mig_rule_min_chapters
import com.sumizuri.app.shared.resources.mig_rule_parallel
import com.sumizuri.app.shared.resources.mig_rule_prefer_more
import com.sumizuri.app.shared.resources.mig_rule_prefer_more_hint
import com.sumizuri.app.shared.resources.mig_rule_read_chapters
import com.sumizuri.app.shared.resources.mig_rule_read_chapters_hint
import com.sumizuri.app.shared.resources.mig_rule_require_author
import com.sumizuri.app.shared.resources.mig_rule_require_author_hint
import com.sumizuri.app.shared.resources.mig_rule_shorter
import com.sumizuri.app.shared.resources.mig_rule_shorter_hint
import com.sumizuri.app.shared.resources.mig_rule_strictness
import com.sumizuri.app.shared.resources.mig_rule_try_address
import com.sumizuri.app.shared.resources.mig_rule_try_address_hint
import com.sumizuri.app.shared.resources.mig_unit_ms
import com.sumizuri.app.ui.kit.page.PageList
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.kit.setting.SliderSetting
import com.sumizuri.app.ui.kit.setting.SwitchSetting
import org.jetbrains.compose.resources.stringResource
import kotlin.math.roundToInt

// How the search picks and accepts matches, how fast it goes, and how a move is done. Each choice is kept for the next time.
@Composable
internal fun MigrationRulesTab(state: MigrationState, session: MigrationSession) {
    val rules = state.rules
    fun change(next: MigrationRules) = session.setRules(next)
    PageList(gap = 14.dp) {
        item { PresetSection(rules, ::change) }
        item {
            SettingsSection(Res.string.mig_group_matching) {
                padded {
                    ChoiceSetting(Res.string.mig_rule_strictness, Strictness.entries, rules.strictness, {
                        stringResource(strictnessLabel(it))
                    }) { change(rules.copy(strictness = it)) }
                }
                padded {
                    SwitchSetting(Res.string.mig_rule_require_author, rules.requireAuthor, {
                        change(rules.copy(requireAuthor = it))
                    }, Res.string.mig_rule_require_author_hint)
                }
                padded {
                    SwitchSetting(Res.string.mig_rule_auto_accept, rules.autoAccept, {
                        change(rules.copy(autoAccept = it))
                    }, Res.string.mig_rule_auto_accept_hint)
                }
            }
        }
        // The rules about chapters only mean something when the chapters are read, so they show only then.
        item {
            SettingsSection(Res.string.mig_group_chapters) {
                padded {
                    SwitchSetting(Res.string.mig_rule_read_chapters, rules.readChapters, {
                        change(rules.copy(readChapters = it))
                    }, Res.string.mig_rule_read_chapters_hint)
                }
                if (rules.readChapters) {
                    padded {
                        SliderSetting(Res.string.mig_rule_looks_at, rules.looksAt.toFloat(), 1f..8f, {
                            it.roundToInt().toString()
                        }) { change(rules.copy(looksAt = it.roundToInt())) }
                    }
                    padded {
                        ChoiceSetting(Res.string.mig_rule_chapters, ChapterRule.entries, rules.chapterRule, {
                            stringResource(chapterRuleLabel(it))
                        }) { change(rules.copy(chapterRule = it)) }
                    }
                    padded {
                        SliderSetting(Res.string.mig_rule_min_chapters, rules.minChapters.toFloat(), 0f..200f, {
                            it.roundToInt().toString()
                        }) { change(rules.copy(minChapters = it.roundToInt())) }
                    }
                    padded {
                        SwitchSetting(Res.string.mig_rule_prefer_more, rules.preferMoreChapters, {
                            change(rules.copy(preferMoreChapters = it))
                        }, Res.string.mig_rule_prefer_more_hint)
                    }
                }
            }
        }
        item {
            SettingsSection(Res.string.mig_group_searching) {
                padded {
                    SwitchSetting(Res.string.mig_rule_shorter, rules.tryShorterName, {
                        change(rules.copy(tryShorterName = it))
                    }, Res.string.mig_rule_shorter_hint)
                }
                padded {
                    SwitchSetting(Res.string.mig_rule_try_address, rules.tryAddress, {
                        change(rules.copy(tryAddress = it))
                    }, Res.string.mig_rule_try_address_hint)
                }
                padded {
                    SwitchSetting(Res.string.mig_rule_compare_all, rules.compareAll, {
                        change(rules.copy(compareAll = it))
                    }, Res.string.mig_rule_compare_all_hint)
                }
            }
        }
        item {
            SettingsSection(Res.string.mig_group_pace) {
                padded {
                    SliderSetting(Res.string.mig_rule_parallel, rules.parallel.toFloat(), 1f..4f, {
                        it.roundToInt().toString()
                    }) { change(rules.copy(parallel = it.roundToInt())) }
                }
                padded {
                    SliderSetting(Res.string.mig_rule_delay, rules.delayMs.toFloat(), 0f..2000f, {
                        stringResource(
                            Res.string.mig_unit_ms,
                            (it / 50).roundToInt() * 50,
                        )
                    }) { change(rules.copy(delayMs = (it / 50).roundToInt() * 50)) }
                }
                padded {
                    SliderSetting(Res.string.mig_rule_give_up, rules.giveUpAfter.toFloat(), 1f..20f, {
                        it.roundToInt().toString()
                    }) { change(rules.copy(giveUpAfter = it.roundToInt())) }
                }
            }
        }
        item {
            SettingsSection(Res.string.mig_group_moving) {
                padded {
                    SwitchSetting(Res.string.mig_rule_keep_old, rules.keepOld, {
                        change(rules.copy(keepOld = it))
                    }, Res.string.mig_rule_keep_old_hint)
                }
                padded {
                    SwitchSetting(
                        Res.string.mig_rule_keep_shelves,
                        rules.keepShelves,
                        { change(rules.copy(keepShelves = it)) },
                    )
                }
                padded {
                    SwitchSetting(
                        Res.string.mig_rule_keep_favorite,
                        rules.keepFavorite,
                        { change(rules.copy(keepFavorite = it)) },
                    )
                }
                padded {
                    SwitchSetting(Res.string.mig_rule_allow_merge, rules.allowMerge, {
                        change(rules.copy(allowMerge = it))
                    }, Res.string.mig_rule_allow_merge_hint)
                }
            }
        }
    }
}
