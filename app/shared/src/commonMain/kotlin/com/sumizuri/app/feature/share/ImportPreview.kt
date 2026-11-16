package com.sumizuri.app.feature.share

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.luminance
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.blocks.decodeBlock
import com.sumizuri.app.data.settings.settingsCount
import com.sumizuri.app.data.share.ShareKind
import com.sumizuri.app.data.share.SharedThing
import com.sumizuri.app.data.share.reposOf
import com.sumizuri.app.data.text.dateText
import com.sumizuri.app.feature.theme.ThemeCard
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.import_block
import com.sumizuri.app.shared.resources.import_made
import com.sumizuri.app.shared.resources.import_repos
import com.sumizuri.app.shared.resources.import_settings
import com.sumizuri.app.shared.resources.share_kind_backup
import com.sumizuri.app.shared.resources.share_kind_block
import com.sumizuri.app.shared.resources.share_kind_repos
import com.sumizuri.app.shared.resources.share_kind_settings
import com.sumizuri.app.shared.resources.share_kind_theme
import com.sumizuri.app.shared.resources.take_block
import com.sumizuri.app.shared.resources.take_repos
import com.sumizuri.app.shared.resources.take_settings
import com.sumizuri.app.shared.resources.take_theme
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.theme.spec.AppThemeSpec
import kotlinx.serialization.json.jsonObject
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// What a file holds, shown before it is taken: the theme drawn in its colors, the repos by name, or how many settings or what block it is.
@Composable
internal fun ImportPreview(thing: SharedThing, theme: AppThemeSpec?) {
    AppCard(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(stringResource(kindName(thing.kind)), style = MaterialTheme.typography.titleMedium)
            thing.made?.let {
                Text(
                    stringResource(Res.string.import_made, dateText(it)),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
            }
            when (thing.kind) {
                ShareKind.Theme -> if (theme != null) {
                    val dark = MaterialTheme.colorScheme.background.luminance() < 0.5f
                    ThemeCard(
                        theme,
                        dark,
                        selected = false,
                        actions = emptyList(),
                        onClick = {},
                        modifier = Modifier.width(200.dp),
                    )
                }

                ShareKind.Settings -> {
                    val count = remember(thing) { settingsCount(thing.data.jsonObject) }
                    Text(pluralStringResource(Res.plurals.import_settings, count, count))
                }

                ShareKind.Block -> {
                    val block = remember(thing) { decodeBlock(thing.data) }
                    Text(stringResource(Res.string.import_block, block?.w ?: 0))
                }

                ShareKind.Repos -> {
                    val repos = remember(thing) { reposOf(thing) }
                    Text(pluralStringResource(Res.plurals.import_repos, repos.size, repos.size))
                    for (repo in repos) {
                        Column {
                            Text(
                                repo.name,
                                style = MaterialTheme.typography.bodyMedium,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                            )
                            Text(
                                repo.url,
                                style = MaterialTheme.typography.bodySmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                            )
                        }
                    }
                }

                ShareKind.Backup -> Unit
            }
        }
    }
}

internal fun kindName(kind: ShareKind): StringResource = when (kind) {
    ShareKind.Backup -> Res.string.share_kind_backup
    ShareKind.Settings -> Res.string.share_kind_settings
    ShareKind.Theme -> Res.string.share_kind_theme
    ShareKind.Block -> Res.string.share_kind_block
    ShareKind.Repos -> Res.string.share_kind_repos
}

internal fun takeLabel(kind: ShareKind): StringResource = when (kind) {
    ShareKind.Settings -> Res.string.take_settings
    ShareKind.Theme -> Res.string.take_theme
    ShareKind.Block -> Res.string.take_block
    ShareKind.Repos -> Res.string.take_repos
    ShareKind.Backup -> Res.string.share_kind_backup
}
