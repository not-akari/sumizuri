package com.sumizuri.app.feature.tv.settings.system

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.account.DeviceSecret
import com.sumizuri.app.data.net.Connection
import com.sumizuri.app.data.net.ConnectionType
import com.sumizuri.app.data.net.LinkState
import com.sumizuri.app.data.net.Network
import com.sumizuri.app.data.net.NetworkEngine
import com.sumizuri.app.data.net.NetworkSetting
import com.sumizuri.app.data.net.Traffic
import com.sumizuri.app.feature.settings.system.Dot
import com.sumizuri.app.feature.settings.system.TraceLine
import com.sumizuri.app.feature.settings.system.TraceRow
import com.sumizuri.app.feature.settings.system.dotColor
import com.sumizuri.app.feature.settings.system.stateWord
import com.sumizuri.app.feature.settings.system.traceAll
import com.sumizuri.app.feature.settings.system.trafficName
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.network_add
import com.sumizuri.app.shared.resources.network_connections
import com.sumizuri.app.shared.resources.network_kept_plain
import com.sumizuri.app.shared.resources.network_kept_sealed
import com.sumizuri.app.shared.resources.network_routes_hint
import com.sumizuri.app.shared.resources.network_routes_title
import com.sumizuri.app.shared.resources.network_status_mixed
import com.sumizuri.app.shared.resources.network_status_straight
import com.sumizuri.app.shared.resources.network_status_through
import com.sumizuri.app.shared.resources.network_straight
import com.sumizuri.app.shared.resources.network_test_short
import com.sumizuri.app.shared.resources.network_testing
import com.sumizuri.app.shared.resources.settings_network
import com.sumizuri.app.shared.resources.settings_network_hint
import com.sumizuri.app.ui.tv.TvButton
import com.sumizuri.app.ui.tv.TvChoiceRow
import com.sumizuri.app.ui.tv.TvRow
import com.sumizuri.app.ui.tv.hiddenUnder
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource
import kotlin.random.Random

// The kinds of traffic a TV has: its videos, and everything else such as sync and trackers.
private val TvTraffic = listOf(Traffic.Anime, Traffic.Other)

// How a TV reaches the sites: where the traffic goes with a test, the way of videos and of the rest, and the connections, each opened in an editor made for the remote.
@Composable
internal fun TvNetworkRoute() {
    val setting by Network.setting.collectAsStateWithLifecycle()
    val states by NetworkEngine.states.collectAsStateWithLifecycle()
    var editing by remember { mutableStateOf<Connection?>(null) }
    Box(Modifier.fillMaxSize()) {
        TvSystemPage(
            stringResource(Res.string.settings_network),
            stringResource(Res.string.settings_network_hint),
            Modifier.hiddenUnder(editing != null),
        ) { first ->
            Status(setting, Modifier.focusRequester(first))
            Ways(setting)
            Connections(setting, states) { editing = it }
        }
        editing?.let { connection ->
            TvConnectionEditor(
                connection,
                isNew = setting.connection(connection.id) == null,
                problem = (states[connection.id] as? LinkState.Failed)?.message,
                onSave = { saved ->
                    val at = setting.connections.indexOfFirst { it.id == saved.id }
                    val list = if (at < 0) {
                        setting.connections + saved
                    } else {
                        setting.connections.toMutableList().also { it[at] = saved }
                    }
                    Network.save(setting.copy(connections = list))
                    editing = null
                },
                onDelete = {
                    Network.save(
                        setting.copy(
                            connections = setting.connections.filterNot { it.id == connection.id },
                            routes = setting.routes.filterValues { it != connection.id },
                            sourceRoutes = setting.sourceRoutes.filterValues { it != connection.id },
                        ),
                    )
                    editing = null
                },
                onClose = { editing = null },
            )
        }
    }
}

// Where the traffic goes now, with OK running a test that asks where the sites see the TV come from.
@Composable
private fun Status(setting: NetworkSetting, modifier: Modifier) {
    val scope = rememberCoroutineScope()
    var lines by remember { mutableStateOf<List<TraceLine>?>(null) }
    var testing by remember { mutableStateOf(false) }
    val straight = stringResource(Res.string.network_straight)
    val ways = Traffic.entries.map { setting.connectionFor(it)?.name }.distinct()
    TvInfoRow(
        when {
            ways == listOf(null) -> stringResource(Res.string.network_status_straight)
            ways.size == 1 -> stringResource(Res.string.network_status_through, ways.first().orEmpty())
            else -> stringResource(Res.string.network_status_mixed)
        },
        null,
        stringResource(if (testing) Res.string.network_testing else Res.string.network_test_short),
        {
            if (!testing) {
                testing = true
                scope.launch {
                    lines = traceAll(setting.connections.filter { it.ready }, straight)
                    testing = false
                }
            }
        },
        modifier,
    )
    lines?.let { found ->
        Column(Modifier.padding(horizontal = 22.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            found.forEach { TraceRow(it) }
        }
    }
}

// The way of each kind of traffic, and of the single sources that have their own, changed with left and right.
@Composable
private fun Ways(setting: NetworkSetting) {
    val installed by LocalAppContainer.current.sources.installed
        .collectAsStateWithLifecycle(emptyList())
    val options = listOf("") + setting.connections.map { it.id }
    val straight = stringResource(Res.string.network_straight)
    val label: @Composable (String) -> String = { id -> setting.connection(id)?.name ?: straight }
    TvGroupTitle(stringResource(Res.string.network_routes_title))
    Hint(stringResource(Res.string.network_routes_hint))
    for (traffic in TvTraffic) {
        TvChoiceRow(trafficName(traffic), options, setting.routes[traffic].orEmpty(), label, { picked ->
            val routes = if (picked.isEmpty()) setting.routes - traffic else setting.routes + (traffic to picked)
            Network.save(setting.copy(routes = routes))
        })
    }
    for ((sourceId, way) in setting.sourceRoutes) {
        TvChoiceRow(installed.firstOrNull { it.id == sourceId }?.name ?: sourceId, options, way, label, { picked ->
            Network.save(setting.copy(sourceRoutes = setting.sourceRoutes + (sourceId to picked)))
        })
    }
}

// The connections, each with how it is doing, and a button for each kind that can be added.
@Composable
private fun Connections(setting: NetworkSetting, states: Map<String, LinkState>, onEdit: (Connection) -> Unit) {
    val colors = MaterialTheme.colorScheme
    val sealed = remember { DeviceSecret.canSeal }
    TvGroupTitle(stringResource(Res.string.network_connections))
    Hint(stringResource(if (sealed) Res.string.network_kept_sealed else Res.string.network_kept_plain))
    for (connection in setting.connections) {
        val state = states[connection.id]
        TvRow({ onEdit(connection) }) {
            Column(Modifier.weight(1f)) {
                Text(connection.name, fontSize = 18.sp, color = colors.onSurface, maxLines = 1)
                Text(
                    stringResource(connection.type.label) + " · " + stateWord(state),
                    fontSize = 14.sp,
                    color = colors.onSurfaceVariant,
                )
            }
            Dot(dotColor(state))
        }
    }
    Text(stringResource(Res.string.network_add), Modifier.padding(start = 4.dp, top = 6.dp), fontSize = 16.sp)
    Row(horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
        for (type in ConnectionType.entries) {
            val name = stringResource(type.label)
            TvButton(name, { onEdit(Connection(Random.nextLong().toULong().toString(36), name, type)) }, main = false)
        }
    }
}

@Composable
private fun Hint(text: String) {
    Text(
        text,
        Modifier.padding(horizontal = 4.dp),
        fontSize = 14.sp,
        lineHeight = 20.sp,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
    )
}
