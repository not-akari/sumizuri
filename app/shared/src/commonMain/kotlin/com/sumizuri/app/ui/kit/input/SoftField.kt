package com.sumizuri.app.ui.kit.input

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.onFocusChanged
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs

// A field to type in, drawn as a soft card that gets a thin accent edge while it is being typed in. One line unless more are asked for.
@Composable
fun SoftField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    hint: String = "",
    singleLine: Boolean = true,
    minLines: Int = 1,
    // Called when the key that ends the line is pressed, for a field that adds what was typed.
    onDone: (() -> Unit)? = null,
) {
    var focused by remember { mutableStateOf(false) }
    val edge by animateColorAsState(
        if (focused) MaterialTheme.colorScheme.primary.copy(alpha = 0.7f) else Color.Transparent,
        tween(motionMs(AppMotion.Fast)),
        label = "field edge",
    )
    val shape = MaterialTheme.shapes.small
    BasicTextField(
        value,
        onValueChange,
        modifier
            .fillMaxWidth()
            .heightIn(min = 44.dp)
            .softCard(lit = focused, shape = shape)
            .border(1.dp, edge, shape)
            .onFocusChanged { focused = it.isFocused },
        singleLine = singleLine,
        minLines = if (singleLine) 1 else minLines,
        textStyle = MaterialTheme.typography.bodyLarge.copy(color = MaterialTheme.colorScheme.onSurface),
        cursorBrush = SolidColor(MaterialTheme.colorScheme.primary),
        keyboardOptions = if (onDone != null) KeyboardOptions(imeAction = ImeAction.Done) else KeyboardOptions.Default,
        keyboardActions = KeyboardActions(onDone = { onDone?.invoke() }),
        decorationBox = { field ->
            Box(
                Modifier.padding(horizontal = 14.dp, vertical = 11.dp),
                contentAlignment = if (singleLine) Alignment.CenterStart else Alignment.TopStart,
            ) {
                if (value.isEmpty() && hint.isNotEmpty()) {
                    Text(hint, color = MaterialTheme.colorScheme.outline, style = MaterialTheme.typography.bodyLarge)
                }
                field()
            }
        },
    )
}
