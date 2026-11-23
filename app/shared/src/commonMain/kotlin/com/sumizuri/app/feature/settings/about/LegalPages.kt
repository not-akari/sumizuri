package com.sumizuri.app.feature.settings.about

import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.legal_choice_1
import com.sumizuri.app.shared.resources.legal_choice_2
import com.sumizuri.app.shared.resources.legal_choice_title
import com.sumizuri.app.shared.resources.legal_intro
import com.sumizuri.app.shared.resources.legal_names_1
import com.sumizuri.app.shared.resources.legal_names_title
import com.sumizuri.app.shared.resources.legal_provide_1
import com.sumizuri.app.shared.resources.legal_provide_2
import com.sumizuri.app.shared.resources.legal_provide_3
import com.sumizuri.app.shared.resources.legal_provide_title
import com.sumizuri.app.shared.resources.legal_rights_1
import com.sumizuri.app.shared.resources.legal_rights_title
import com.sumizuri.app.shared.resources.legal_title
import com.sumizuri.app.shared.resources.legal_warranty_1
import com.sumizuri.app.shared.resources.legal_warranty_title
import com.sumizuri.app.shared.resources.legal_what_1
import com.sumizuri.app.shared.resources.legal_what_2
import com.sumizuri.app.shared.resources.legal_what_title
import com.sumizuri.app.shared.resources.privacy_changes_1
import com.sumizuri.app.shared.resources.privacy_changes_title
import com.sumizuri.app.shared.resources.privacy_control_1
import com.sumizuri.app.shared.resources.privacy_control_title
import com.sumizuri.app.shared.resources.privacy_device_1
import com.sumizuri.app.shared.resources.privacy_device_2
import com.sumizuri.app.shared.resources.privacy_device_title
import com.sumizuri.app.shared.resources.privacy_intro
import com.sumizuri.app.shared.resources.privacy_leaves_browser
import com.sumizuri.app.shared.resources.privacy_leaves_lookup
import com.sumizuri.app.shared.resources.privacy_leaves_repos
import com.sumizuri.app.shared.resources.privacy_leaves_sources
import com.sumizuri.app.shared.resources.privacy_leaves_sync
import com.sumizuri.app.shared.resources.privacy_leaves_title
import com.sumizuri.app.shared.resources.privacy_leaves_updates
import com.sumizuri.app.shared.resources.privacy_short_1
import com.sumizuri.app.shared.resources.privacy_short_title
import com.sumizuri.app.shared.resources.privacy_title
import com.sumizuri.app.ui.kit.setting.SettingsSection
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// The parts of the legal page, each a heading with its paragraphs.
internal val LegalParts = listOf(
    Res.string.legal_what_title to listOf(Res.string.legal_what_1, Res.string.legal_what_2),
    Res.string.legal_provide_title to
        listOf(Res.string.legal_provide_1, Res.string.legal_provide_2, Res.string.legal_provide_3),
    Res.string.legal_choice_title to listOf(Res.string.legal_choice_1, Res.string.legal_choice_2),
    Res.string.legal_rights_title to listOf(Res.string.legal_rights_1),
    Res.string.legal_names_title to listOf(Res.string.legal_names_1),
    Res.string.legal_warranty_title to listOf(Res.string.legal_warranty_1),
)

// The parts of the privacy page. Each line of what leaves the device names one place the app talks to.
internal val PrivacyParts = listOf(
    Res.string.privacy_short_title to listOf(Res.string.privacy_short_1),
    Res.string.privacy_device_title to listOf(Res.string.privacy_device_1, Res.string.privacy_device_2),
    Res.string.privacy_leaves_title to listOf(
        Res.string.privacy_leaves_sources,
        Res.string.privacy_leaves_repos,
        Res.string.privacy_leaves_updates,
        Res.string.privacy_leaves_lookup,
        Res.string.privacy_leaves_browser,
        Res.string.privacy_leaves_sync,
    ),
    Res.string.privacy_control_title to listOf(Res.string.privacy_control_1),
    Res.string.privacy_changes_title to listOf(Res.string.privacy_changes_1),
)

// What the app is and is not: a viewer that brings no content of its own.
@Composable
fun LegalRoute(onBack: () -> Unit) = TextPage(Res.string.legal_title, Res.string.legal_intro, LegalParts, onBack)

// What stays on the device and each place the app sends something to.
@Composable
fun PrivacyRoute(onBack: () -> Unit) =
    TextPage(Res.string.privacy_title, Res.string.privacy_intro, PrivacyParts, onBack)

@Composable
private fun TextPage(
    title: StringResource,
    intro: StringResource,
    parts: List<Pair<StringResource, List<StringResource>>>,
    onBack: () -> Unit,
) {
    SettingsPageFrame(title, onBack, subtitle = intro) {
        for ((heading, paragraphs) in parts) {
            SettingsSection(heading) {
                for (paragraph in paragraphs) {
                    padded {
                        Text(
                            stringResource(paragraph),
                            Modifier.padding(vertical = 4.dp),
                            style = MaterialTheme.typography.bodyMedium,
                        )
                    }
                }
            }
        }
    }
}
