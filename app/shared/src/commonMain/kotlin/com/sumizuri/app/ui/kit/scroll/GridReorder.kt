package com.sumizuri.app.ui.kit.scroll

import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.waitForUpOrCancellation
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.lazy.grid.LazyGridItemInfo
import androidx.compose.foundation.lazy.grid.LazyGridItemScope
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.Stable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.PointerEventPass
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChange
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.toOffset
import androidx.compose.ui.zIndex
import kotlinx.coroutines.withTimeoutOrNull

// The cells of a lazy grid that can be held and dragged to a new place. A tap opens a cell, a hold that does not move asks for its actions, and a hold that moves carries it, with the grid scrolling near its edges.
@Stable
class GridReorder<T> internal constructor(private val state: LazyGridState, private val keyOf: (T) -> Any) {
    // The cells in the order shown, which follows the dragged cell while it moves.
    var order by mutableStateOf<List<T>>(emptyList())
        internal set

    // The key of the cell being carried, or null.
    var held by mutableStateOf<Any?>(null)
        private set
    private var startAt = Offset.Zero
    private var moved by mutableStateOf(Offset.Zero)

    internal fun cellAt(point: Offset): LazyGridItemInfo? = state.layoutInfo.visibleItemsInfo.firstOrNull { cell ->
        val start = cell.offset.toOffset()
        point.x >= start.x && point.y >= start.y && point.x < start.x + cell.size.width &&
            point.y < start.y + cell.size.height
    }

    internal fun itemOf(key: Any): T? = order.firstOrNull { keyOf(it) == key }

    private fun infoOf(key: Any?) = state.layoutInfo.visibleItemsInfo.firstOrNull { it.key == key }

    internal fun lift(cell: LazyGridItemInfo) {
        held = cell.key
        startAt = cell.offset.toOffset()
        moved = Offset.Zero
    }

    // How far the carried cell is drawn from where the grid puts it.
    fun shift(): Offset = infoOf(held)?.let { startAt + moved - it.offset.toOffset() } ?: Offset.Zero

    internal fun carry(by: Offset) {
        moved += by
        val cell = infoOf(held) ?: return
        val middle = cell.offset.toOffset() + shift() + Offset(cell.size.width / 2f, cell.size.height / 2f)
        val target = cellAt(middle)?.takeIf { it.key != held && itemOf(it.key) != null } ?: return
        val from = order.indexOfFirst { keyOf(it) == held }
        val to = order.indexOfFirst { keyOf(it) == target.key }
        if (from < 0 || to < 0) return
        order = order.toMutableList().apply { add(to, removeAt(from)) }
    }

    // Scrolls the grid a little when the pointer is near its top or bottom edge.
    internal fun edgeScroll(y: Float, edge: Float) {
        val height = state.layoutInfo.viewportSize.height
        val by = when {
            y < edge -> -(edge - y) / 4f
            y > height - edge -> (y - (height - edge)) / 4f
            else -> 0f
        }
        if (by != 0f) {
            val done = state.dispatchRawDelta(by)
            moved += Offset(0f, done)
        }
    }

    internal fun drop() {
        held = null
        moved = Offset.Zero
    }
}

// Keeps the order of the grid and follows the items given, except while a cell is carried.
@Composable
fun <T> rememberGridReorder(items: List<T>, key: (T) -> Any, state: LazyGridState): GridReorder<T> {
    val reorder = remember(state) { GridReorder(state, key) }
    if (reorder.held == null && reorder.order != items) reorder.order = items
    return reorder
}

// The gestures of a grid whose cells can be carried. It goes on the modifier of the grid.
fun <T> Modifier.gridReorder(
    reorder: GridReorder<T>,
    onTap: (T) -> Unit,
    onHold: (T) -> Unit,
    onReorder: (List<T>) -> Unit,
): Modifier = pointerInput(reorder) {
    val edge = 56.dp.toPx()
    awaitEachGesture {
        val down = awaitFirstDown(requireUnconsumed = false)
        // Only the cells that can move take the gesture, so a heading in the grid is left alone.
        val cell = reorder.cellAt(down.position)?.takeIf { reorder.itemOf(it.key) != null } ?: return@awaitEachGesture
        var cancelled = false
        val up = withTimeoutOrNull(viewConfiguration.longPressTimeoutMillis) {
            waitForUpOrCancellation().also { if (it == null) cancelled = true }
        }
        if (up != null) {
            reorder.itemOf(cell.key)?.let(onTap)
            return@awaitEachGesture
        }
        if (cancelled) return@awaitEachGesture
        reorder.lift(cell)
        var travel = 0f
        // The early pass takes the moves before the grid can scroll with them.
        while (true) {
            val event = awaitPointerEvent(PointerEventPass.Initial)
            val change = event.changes.firstOrNull { it.id == down.id } ?: break
            if (!change.pressed) {
                change.consume()
                break
            }
            val step = change.positionChange()
            change.consume()
            travel += step.getDistance()
            if (travel > viewConfiguration.touchSlop) {
                reorder.carry(step)
                reorder.edgeScroll(change.position.y, edge)
            }
        }
        val item = reorder.itemOf(cell.key)
        if (travel <= viewConfiguration.touchSlop) item?.let(onHold) else onReorder(reorder.order)
        reorder.drop()
    }
}

// One cell of such a grid. The carried cell floats over the others a little bigger, and the rest slide to their new places.
@Composable
fun <T> LazyGridItemScope.ReorderCell(reorder: GridReorder<T>, key: Any, content: @Composable () -> Unit) {
    val carried = reorder.held == key
    val modifier = if (carried) {
        Modifier
            .zIndex(1f)
            .graphicsLayer {
                val shift = reorder.shift()
                translationX = shift.x
                translationY = shift.y
            }.scale(1.05f)
    } else {
        Modifier.animateItem()
    }
    Box(modifier) { content() }
}
