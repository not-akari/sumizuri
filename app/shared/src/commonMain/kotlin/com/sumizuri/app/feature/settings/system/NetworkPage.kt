package com.sumizuri.app.feature.settings.system

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Article
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.outlined.Add
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Extension
import androidx.compose.material.icons.outlined.Hub
import androidx.compose.material.icons.outlined.Lan
import androidx.compose.material.icons.outlined.Movie
import androidx.compose.material.icons.outlined.Wifi
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
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
import com.sumizuri.app.feature.settings.SettingsPageFrame
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.network_add
import com.sumizuri.app.shared.resources.network_connections
import com.sumizuri.app.shared.resources.network_kept_plain
import com.sumizuri.app.shared.resources.network_kept_sealed
import com.sumizuri.app.shared.resources.network_routes_hint
import com.sumizuri.app.shared.resources.network_routes_title
import com.sumizuri.app.shared.resources.network_source_add
import com.sumizuri.app.shared.resources.network_state_connecting
import com.sumizuri.app.shared.resources.network_state_failed
import com.sumizuri.app.shared.resources.network_state_off
import com.sumizuri.app.shared.resources.network_state_up
import com.sumizuri.app.shared.resources.network_status_mixed
import com.sumizuri.app.shared.resources.network_status_straight
import com.sumizuri.app.shared.resources.network_status_through
import com.sumizuri.app.shared.resources.network_straight
import com.sumizuri.app.shared.resources.network_test_short
import com.sumizuri.app.shared.resources.network_testing
import com.sumizuri.app.shared.resources.network_traffic_anime
import com.sumizuri.app.shared.resources.network_traffic_manga
import com.sumizuri.app.shared.resources.network_traffic_novel
import com.sumizuri.app.shared.resources.network_traffic_other
import com.sumizuri.app.shared.resources.network_traffic_other_hint
import com.sumizuri.app.shared.resources.settings_network
import com.sumizuri.app.shared.resources.settings_network_hint
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.card.AppCard
import com.sumizuri.app.ui.kit.input.MenuButton
import com.sumizuri.app.ui.kit.menu.AppMenu
import com.sumizuri.app.ui.kit.menu.AppMenuItem
import com.sumizuri.app.ui.kit.setting.SettingIcon
import com.sumizuri.app.ui.kit.setting.SettingRow
import com.sumizuri.app.ui.kit.setting.SettingsSection
import kotlinx.coroutines.launch
import org.jetbrains.compose.resources.stringResource
import kotlin.random.Random

// What a test found for one way: the address the sites saw and its country, or why it did not work.
internal class TraceLine(val way: String, val ip: String?, val country: String?, val problem: String?)

// How the app reaches the sites: a card that says where the traffic goes with a test beside it, the way of each kind of title and of single sources, and the connections. Home network addresses always go straight.
@Composable
fun NetworkRoute(onBack: () -> Unit) {
    val setting by Network.setting.collectAsStateWithLifecycle()
    val states by NetworkEngine.states.collectAsStateWithLifecycle()
    var editing by remember { mutableStateOf<Connection?>(null) }
    SettingsPageFrame(Res.string.settings_network, onBack, subtitle = Res.string.settings_network_hint) {
        StatusCard(setting)
        RoutesSection(setting)
        ConnectionsSection(setting, states, onEdit = { editing = it })
    }
    editing?.let { connection ->
        ConnectionDialog(
            connection,
            isNew = setting.connection(connection.id) == null,
            problem = (states[connection.id] as? LinkState.Failed)?.message,
            onSave = { saved ->
                val at = setting.connections.indexOfFirst { it.id == saved.id }
                val list = if (at <
                    0
                ) {
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
            onDismiss = { editing = null },
        )
    }
}

// Where the traffic goes now in one line, and a test that asks where the sites see the app come from, one line for each way.
@Composable
private fun StatusCard(setting: NetworkSetting) {
    val scope = rememberCoroutineScope()
    var lines by remember { mutableStateOf<List<TraceLine>?>(null) }
    var testing by remember { mutableStateOf(false) }
    val straight = stringResource(Res.string.network_straight)
    val ways = Traffic.entries.map { setting.connectionFor(it)?.name }.distinct()
    val title = when {
        ways == listOf(null) -> stringResource(Res.string.network_status_straight)
        ways.size == 1 -> stringResource(Res.string.network_status_through, ways.first().orEmpty())
        else -> stringResource(Res.string.network_status_mixed)
    }
    AppCard(Modifier.fillMaxWidth()) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                SettingIcon(Icons.Outlined.Lan)
                Text(
                    title,
                    Modifier.weight(1f),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                )
                InkOutlinedButton({
                    if (!testing) {
                        testing = true
                        scope.launch {
                            lines = traceAll(setting.connections.filter { it.ready }, straight)
                            testing = false
                        }
                    }
                }) { Text(stringResource(if (testing) Res.string.network_testing else Res.string.network_test_short)) }
            }
            lines?.forEach { TraceRow(it) }
        }
    }
}

@Composable
internal fun TraceRow(line: TraceLine) {
    val failed = line.ip == null
    Column {
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Dot(if (failed) BadDot else GoodDot)
            Text(line.way, Modifier.weight(1f), style = MaterialTheme.typography.bodyMedium)
            Text(
                if (failed) stringResource(Res.string.network_state_failed) else "${line.ip} · ${line.country}",
                style = MaterialTheme.typography.bodySmall,
                color = if (failed) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        if (failed && !line.problem.isNullOrBlank()) {
            Text(
                line.problem,
                Modifier.padding(start = 30.dp),
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.outline,
                maxLines = 2,
            )
        }
    }
}

internal suspend fun traceAll(connections: List<Connection>, straight: String): List<TraceLine> =
    (listOf<Connection?>(null) + connections).map { way ->
        val traced = NetworkEngine.trace(way)
        val found = traced.getOrNull()
        TraceLine(way?.name ?: straight, found?.first, found?.second, traced.exceptionOrNull()?.message)
    }

// One line for each kind of title with its way on the right, and under them the single sources that take their own.
@Composable
private fun RoutesSection(setting: NetworkSetting) {
    val installed by LocalAppContainer.current.sources.installed
        .collectAsStateWithLifecycle(emptyList())
    var adding by remember { mutableStateOf(false) }
    val options = listOf("") + setting.connections.map { it.id }
    val straight = stringResource(Res.string.network_straight)
    val label: @Composable (String) -> String = { id -> setting.connection(id)?.name ?: straight }
    SettingsSection(Res.string.network_routes_title, Res.string.network_routes_hint) {
        for (traffic in Traffic.entries) {
            row {
                SettingRow(
                    trafficName(traffic),
                    subtitle = if (traffic ==
                        Traffic.Other
                    ) {
                        stringResource(Res.string.network_traffic_other_hint)
                    } else {
                        null
                    },
                    leading = { SettingIcon(trafficIcon(traffic)) },
                    trailing = {
                        MenuButton(options, setting.routes[traffic].orEmpty(), label) { picked ->
                            val routes = if (picked.isEmpty()) {
                                setting.routes - traffic
                            } else {
                                setting.routes +
                                    (traffic to picked)
                            }
                            Network.save(setting.copy(routes = routes))
                        }
                    },
                )
            }
        }
        for ((sourceId, way) in setting.sourceRoutes) {
            row {
                SettingRow(
                    installed.firstOrNull { it.id == sourceId }?.name ?: sourceId,
                    leading = { SettingIcon(Icons.Outlined.Extension) },
                    trailing = {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            MenuButton(options, way, label) { picked ->
                                Network.save(setting.copy(sourceRoutes = setting.sourceRoutes + (sourceId to picked)))
                            }
                            IconButton({ Network.save(setting.copy(sourceRoutes = setting.sourceRoutes - sourceId)) }) {
                                Icon(Icons.Outlined.Close, null)
                            }
                        }
                    },
                )
            }
        }
        row {
            SettingRow(
                stringResource(Res.string.network_source_add),
                leading = { SettingIcon(Icons.Outlined.Add) },
                onClick = { adding = true },
            )
        }
    }
    if (adding) SourceRouteDialog(setting, installed.filter { it.id !in setting.sourceRoutes }) { adding = false }
}

// The connections, each with a dot for how it is doing and a short word for it. A tap edits one, where a failure is told in full.
@Composable
private fun ConnectionsSection(setting: NetworkSetting, states: Map<String, LinkState>, onEdit: (Connection) -> Unit) {
    var adding by remember { mutableStateOf(false) }
    val sealed = remember { DeviceSecret.canSeal }
    SettingsSection(
        stringResource(Res.string.network_connections),
        stringResource(if (sealed) Res.string.network_kept_sealed else Res.string.network_kept_plain),
    ) {
        for (connection in setting.connections) {
            val state = states[connection.id]
            row {
                SettingRow(
                    connection.name,
                    subtitle = stringResource(connection.type.label) + " · " + stateWord(state),
                    leading = { SettingIcon(Icons.Outlined.Hub) },
                    trailing = { Dot(dotColor(state)) },
                    onClick = { onEdit(connection) },
                )
            }
        }
        row {
            Box {
                SettingRow(
                    stringResource(Res.string.network_add),
                    leading = { SettingIcon(Icons.Outlined.Add) },
                    onClick = { adding = true },
                )
                AppMenu(adding, { adding = false }) {
                    for (type in ConnectionType.entries) {
                        val name = stringResource(type.label)
                        AppMenuItem({ Text(name) }, {
                            adding = false
                            onEdit(Connection(Random.nextLong().toULong().toString(36), name, type))
                        })
                    }
                }
            }
        }
    }
}

@Composable
internal fun trafficName(traffic: Traffic): String = stringResource(
    when (traffic) {
        Traffic.Anime -> Res.string.network_traffic_anime
        Traffic.Manga -> Res.string.network_traffic_manga
        Traffic.Novel -> Res.string.network_traffic_novel
        Traffic.Other -> Res.string.network_traffic_other
    },
)

private fun trafficIcon(traffic: Traffic): ImageVector = when (traffic) {
    Traffic.Anime -> Icons.Outlined.Movie
    Traffic.Manga -> Icons.AutoMirrored.Outlined.MenuBook
    Traffic.Novel -> Icons.AutoMirrored.Outlined.Article
    Traffic.Other -> Icons.Outlined.Wifi
}

@Composable
internal fun stateWord(state: LinkState?): String = stringResource(
    when (state) {
        null, LinkState.Idle -> Res.string.network_state_off
        LinkState.Connecting -> Res.string.network_state_connecting
        LinkState.Up -> Res.string.network_state_up
        is LinkState.Failed -> Res.string.network_state_failed
    },
)

private val GoodDot = Color(0xFF4CAF7A)
private val BadDot = Color(0xFFE5534B)
private val WaitDot = Color(0xFFE0A63A)

@Composable
internal fun dotColor(state: LinkState?): Color = when (state) {
    LinkState.Up -> GoodDot
    is LinkState.Failed -> BadDot
    LinkState.Connecting -> WaitDot
    else -> MaterialTheme.colorScheme.outlineVariant
}

@Composable
internal fun Dot(color: Color) {
    Box(Modifier.padding(horizontal = 6.dp).size(10.dp).background(color, CircleShape))
}
