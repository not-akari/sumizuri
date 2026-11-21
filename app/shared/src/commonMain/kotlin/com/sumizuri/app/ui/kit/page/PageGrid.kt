package com.sumizuri.app.ui.kit.page

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyGridScope
import androidx.compose.foundation.lazy.grid.LazyGridState
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.rememberLazyGridState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.kit.scroll.RegisterScrollTarget
import com.sumizuri.app.ui.kit.scroll.mouseDragScroll

// The grid of covers every page uses, with the page gutter and the same gaps.
@Composable
fun PageGrid(
    modifier: Modifier = Modifier,
    // No cell is wider than this, so a wide window gets more columns and a narrow one fewer, bigger ones.
    maxCell: Dp = 156.dp,
    state: LazyGridState = rememberLazyGridState(),
    // The space between the cells, with a little more under each than beside it.
    gap: Dp = 12.dp,
    // The space between rows, which a list of rows that keep their own room can set to nothing.
    rowGap: Dp = gap + 2.dp,
    // How the columns are counted, by the widest a cell may be unless a page asks for another way.
    columns: GridCells = MaxCellWidth(maxCell),
    content: LazyGridScope.() -> Unit,
) {
    RegisterScrollTarget(state)
    LazyVerticalGrid(
        columns = columns,
        modifier = modifier.mouseDragScroll(state),
        state = state,
        contentPadding = PaddingValues(
            start = PageGutter,
            end = PageGutter,
            top = 8.dp,
            bottom =
            8.dp + LocalBottomClearance.current,
        ),
        horizontalArrangement = Arrangement.spacedBy(gap),
        verticalArrangement = Arrangement.spacedBy(rowGap),
        content = content,
    )
}
