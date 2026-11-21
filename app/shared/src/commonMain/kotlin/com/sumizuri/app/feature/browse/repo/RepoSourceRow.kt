package com.sumizuri.app.feature.browse.repo

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.DeleteOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.net.siteNameOf
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.install
import com.sumizuri.app.shared.resources.reinstall
import com.sumizuri.app.shared.resources.remove
import com.sumizuri.app.shared.resources.repo_nsfw_badge
import com.sumizuri.app.shared.resources.repo_tile_version
import com.sumizuri.app.shared.resources.update
import com.sumizuri.app.source.repo.RepoSource
import com.sumizuri.app.source.repo.versionText
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.art.InkTonalButton
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.kit.cover.SourceMark
import org.jetbrains.compose.resources.stringResource

// One source of a repo as a soft tile like the installed ones: its icon, its name with the marks of a source that runs code or is for adults, its version and the site it reads, and the one thing to do with it: install, update, or install again, and remove once it is installed.
@Composable
fun RepoSourceRow(
    source: RepoSource,
    have: InstalledRef?,
    busy: Boolean,
    onInstall: () -> Unit,
    onRemove: () -> Unit,
    modifier: Modifier = Modifier,
) {
    Row(
        modifier.fillMaxWidth().softCard().padding(start = 12.dp, end = 8.dp, top = 10.dp, bottom = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        SourceMark(source.iconUrl, size = 40.dp)
        Column(Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(
                    source.name,
                    Modifier.weight(1f, fill = false),
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                if (source.nsfw) {
                    Text(
                        stringResource(Res.string.repo_nsfw_badge),
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.error,
                        fontWeight = FontWeight.Bold,
                    )
                }
            }
            Text(
                stringResource(Res.string.repo_tile_version, versionText(source.version), siteNameOf(source.baseUrl)),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.outline,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
        }
        if (busy) {
            InkCircularProgressIndicator(Modifier.padding(horizontal = 12.dp).size(22.dp), strokeWidth = 2.dp)
        } else {
            val outdated = have != null && have.version < source.version
            val label =
                Res.string.install.takeIf { have == null } ?: Res.string.update.takeIf { outdated }
                    ?: Res.string.reinstall
            if (have != null && !outdated) {
                InkOutlinedButton(onInstall, Modifier.height(34.dp)) { Text(stringResource(label), maxLines = 1) }
            } else {
                InkTonalButton(onInstall, Modifier.height(34.dp)) { Text(stringResource(label), maxLines = 1) }
            }
            if (have != null) {
                IconButton(onRemove, Modifier.size(36.dp)) {
                    Icon(
                        Icons.Outlined.DeleteOutline,
                        stringResource(Res.string.remove),
                        Modifier.size(20.dp),
                        tint = MaterialTheme.colorScheme.outline,
                    )
                }
            }
        }
    }
}

// The site a source reads from, as a person would say it.
