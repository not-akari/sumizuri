package com.sumizuri.app.feature.settings.system

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.net.Network
import com.sumizuri.app.data.net.NetworkSetting
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.network_source_add
import com.sumizuri.app.shared.resources.network_source_route
import com.sumizuri.app.shared.resources.network_source_source
import com.sumizuri.app.shared.resources.network_straight
import com.sumizuri.app.shared.resources.save
import com.sumizuri.app.source.repo.InstalledSource
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.dialog.AppDialog
import com.sumizuri.app.ui.kit.dialog.CancelButton
import com.sumizuri.app.ui.kit.setting.ChoiceSetting
import org.jetbrains.compose.resources.stringResource

// Adds a rule that sends one source another way than its kind, such as one source of manga through a server while the rest go straight.
@Composable
internal fun SourceRouteDialog(setting: NetworkSetting, sources: List<InstalledSource>, onDone: () -> Unit) {
    var source by remember { mutableStateOf(sources.firstOrNull()) }
    var way by remember { mutableStateOf("") }
    val straight = stringResource(Res.string.network_straight)
    AppDialog(
        onDismissRequest = onDone,
        title = { Text(stringResource(Res.string.network_source_add)) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                if (sources.isNotEmpty()) {
                    ChoiceSetting(Res.string.network_source_source, sources, source ?: sources.first(), { it.name }) {
                        source =
                            it
                    }
                }
                val ways = listOf("") + setting.connections.map { it.id }
                ChoiceSetting(Res.string.network_source_route, ways, way, { id ->
                    setting.connection(id)?.name
                        ?: straight
                }) { way = it }
            }
        },
        confirmButton = {
            InkButton({
                source?.let { Network.save(setting.copy(sourceRoutes = setting.sourceRoutes + (it.id to way))) }
                onDone()
            }, enabled = source != null) { Text(stringResource(Res.string.save)) }
        },
        dismissButton = { CancelButton(onDone) },
    )
}
