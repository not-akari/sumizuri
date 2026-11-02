package com.sumizuri.app.feature.profile

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.AutoAwesomeMosaic
import androidx.compose.material.icons.outlined.DashboardCustomize
import androidx.compose.material.icons.outlined.LinkOff
import androidx.compose.material.icons.outlined.Settings
import androidx.compose.material.icons.outlined.Sync
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.account.LibrarySyncer
import com.sumizuri.app.data.account.SyncRun
import com.sumizuri.app.data.profile.LocalProfiles
import com.sumizuri.app.data.profile.Profile
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.feature.profile.blocks.BlockEnv
import com.sumizuri.app.feature.profile.blocks.BlockGrid
import com.sumizuri.app.feature.profile.blocks.LayoutsDialog
import com.sumizuri.app.feature.settings.PageRow
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.blocks_edit
import com.sumizuri.app.shared.resources.blocks_layouts
import com.sumizuri.app.shared.resources.nav_settings
import com.sumizuri.app.shared.resources.profile_title
import com.sumizuri.app.shared.resources.settings_missing_sources
import com.sumizuri.app.shared.resources.sync_hint
import com.sumizuri.app.shared.resources.sync_last_at
import com.sumizuri.app.shared.resources.sync_state_failed
import com.sumizuri.app.shared.resources.sync_state_never
import com.sumizuri.app.shared.resources.sync_state_ok
import com.sumizuri.app.shared.resources.sync_state_running
import com.sumizuri.app.shared.resources.sync_state_unlinked
import com.sumizuri.app.shared.resources.sync_title
import com.sumizuri.app.shared.resources.titles_count
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.page.PageTopBar
import com.sumizuri.app.ui.kit.page.pageScroll
import com.sumizuri.app.ui.kit.setting.SettingsSection
import com.sumizuri.app.ui.text.agoText
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// The windows the page can open over itself. Editing carries the profile being edited, and null makes a new one.
private sealed interface Window {
    data object None : Window
    data object Switch : Window
    data class Form(val profile: Profile?) : Window
    data object Layouts : Window
}

// The profile page: the reader's picture and name, a word when titles have lost their source, and under them the blocks the reader laid out, each made by a short script of JSON and formulas. At the top right are the layouts to start from, the page where the blocks are put in order, sized, added and removed, and the settings.
@Composable
internal fun ProfileScreen(state: ProfileState, calls: ProfileCalls) {
    var window by remember { mutableStateOf<Window>(Window.None) }
    val active = state.active
    Column(Modifier.fillMaxSize()) {
        // The bar sits over the content, centered with it on a wide window.
        Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.TopCenter) {
            Box(Modifier.widthIn(max = ContentWidth).fillMaxWidth()) {
                PageTopBar(stringResource(Res.string.profile_title)) {
                    IconButton({
                        window = Window.Layouts
                    }) { Icon(Icons.Outlined.AutoAwesomeMosaic, stringResource(Res.string.blocks_layouts)) }
                    IconButton(
                        calls.onArrange,
                    ) { Icon(Icons.Outlined.DashboardCustomize, stringResource(Res.string.blocks_edit)) }
                    IconButton(
                        calls.onOpenSettings,
                    ) { Icon(Icons.Outlined.Settings, stringResource(Res.string.nav_settings)) }
                }
            }
        }
        if (active != null) {
            BoxWithConstraints(Modifier.weight(1f).fillMaxWidth()) {
                val wide = maxWidth >= WideBreakpoint
                Column(Modifier.fillMaxSize().pageScroll(), horizontalAlignment = Alignment.CenterHorizontally) {
                    Column(
                        Modifier
                            .widthIn(max = ContentWidth)
                            .fillMaxWidth()
                            .padding(horizontal = PageGutter)
                            .padding(top = 12.dp, bottom = 32.dp),
                        verticalArrangement = Arrangement.spacedBy(24.dp),
                    ) {
                        ProfileHeader(active, onSwitch = { window = Window.Switch }, onEdit = {
                            window =
                                Window.Form(active)
                        })
                        SyncEntry(calls.onOpenSync)
                        if (state.unreachable > 0) Missing(state.unreachable, calls.onOpenMissing)
                        BlockGrid(
                            state.blocks,
                            BlockEnv(state.stats, state.recent, wide, calls.onOpenTitle),
                            onAdd = calls.onArrange,
                        )
                    }
                }
            }
        }
    }
    val close = { window = Window.None }
    when (val open = window) {
        Window.None -> Unit

        Window.Switch -> ProfileSwitchSheet(
            state.profiles,
            active,
            onSwitch = calls.onSwitch,
            onEdit = { window = Window.Form(it) },
            onNew = { window = Window.Form(null) },
            onDismiss = close,
        )

        is Window.Form -> ProfileFormSheet(open.profile, open.profile?.id == active?.id, calls, close)

        Window.Layouts -> LayoutsDialog(calls.onPreset, close)
    }
}

// The way to sync, saying how the sync of this profile stands, or what sync is while it is not set up.
@Composable
private fun SyncEntry(onOpen: () -> Unit) {
    val account by LocalProfiles.current.syncAccounts.account
        .collectAsStateWithLifecycle()
    // Once signed in the row says how the sync stands, so a sync that did not finish shows without opening the page.
    val container = LocalAppContainer.current
    val run by container.librarySync.run.collectAsStateWithLifecycle()
    val lastAt by remember(
        container,
    ) { container.settings.text(LibrarySyncer.LastAtKey) }.collectAsStateWithLifecycle(null)
    val linked by remember(container) {
        container.settings.text(SettingKey.SyncLibraryId)
    }.collectAsStateWithLifecycle(null)
    val summary = when {
        account == null -> stringResource(Res.string.sync_hint)

        linked == null -> stringResource(Res.string.sync_state_unlinked)

        run == SyncRun.Running -> stringResource(Res.string.sync_state_running)

        run is SyncRun.Failed -> stringResource(Res.string.sync_state_failed)

        else -> {
            val at = (run as? SyncRun.Done)?.at ?: lastAt?.toLongOrNull()
            if (at ==
                null
            ) {
                stringResource(Res.string.sync_state_never)
            } else {
                stringResource(Res.string.sync_state_ok) + " · " +
                    stringResource(Res.string.sync_last_at, agoText(at))
            }
        }
    }
    SettingsSection {
        row { PageRow(Icons.Outlined.Sync, stringResource(Res.string.sync_title), summary, onOpen) }
    }
}

// The titles whose source is missing or off need a hand, so the way to them shows while there are any.
@Composable
private fun Missing(count: Int, onOpen: () -> Unit) {
    val missing = stringResource(Res.string.settings_missing_sources)
    val titles = pluralStringResource(Res.plurals.titles_count, count, count)
    SettingsSection {
        row { PageRow(Icons.Outlined.LinkOff, missing, titles, onOpen) }
    }
}

// Wide enough to put the statistics in two columns.
private val WideBreakpoint = 900.dp

// The widest the content grows before it is centered.
private val ContentWidth = 1100.dp
