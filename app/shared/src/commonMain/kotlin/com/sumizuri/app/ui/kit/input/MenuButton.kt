package com.sumizuri.app.ui.kit.input

import androidx.compose.foundation.layout.Box
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.menu.AppMenu
import com.sumizuri.app.ui.kit.menu.AppMenuItem

// A small button with the chosen value on it, which opens a menu of the others. It is for a row that has several choices side by side.
@Composable
fun <T> MenuButton(
    options: List<T>,
    selected: T,
    label: @Composable (T) -> String,
    modifier: Modifier = Modifier,
    onSelect: (T) -> Unit,
) {
    var open by remember { mutableStateOf(false) }
    Box(modifier) {
        InkOutlinedButton({ open = true }) {
            Text(label(selected), maxLines = 1, overflow = TextOverflow.Ellipsis)
            Icon(Icons.Filled.ArrowDropDown, null)
        }
        AppMenu(open, { open = false }) {
            for (option in options) {
                AppMenuItem({ Text(label(option)) }, {
                    open = false
                    onSelect(option)
                })
            }
        }
    }
}
