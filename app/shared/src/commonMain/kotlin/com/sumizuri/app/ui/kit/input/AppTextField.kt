package com.sumizuri.app.ui.kit.input

import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.LocalTextStyle
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldColors
import androidx.compose.material3.TextFieldDefaults
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.input.TextFieldValue
import androidx.compose.ui.text.input.VisualTransformation
import com.sumizuri.app.ui.kit.card.softFill

// The field to type in with a label, in the soft look of the cards: a light wash of the accent with no outline, a little lighter while it is typed in, and a red line under it when what is in it is wrong. It takes what the outlined field of Material takes, in the same order.
@Composable
fun AppTextField(
    value: String,
    onValueChange: (String) -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    readOnly: Boolean = false,
    textStyle: TextStyle = LocalTextStyle.current,
    label: (@Composable () -> Unit)? = null,
    placeholder: (@Composable () -> Unit)? = null,
    leadingIcon: (@Composable () -> Unit)? = null,
    trailingIcon: (@Composable () -> Unit)? = null,
    prefix: (@Composable () -> Unit)? = null,
    suffix: (@Composable () -> Unit)? = null,
    supportingText: (@Composable () -> Unit)? = null,
    isError: Boolean = false,
    visualTransformation: VisualTransformation = VisualTransformation.None,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    keyboardActions: KeyboardActions = KeyboardActions.Default,
    singleLine: Boolean = false,
    maxLines: Int = if (singleLine) 1 else Int.MAX_VALUE,
    minLines: Int = 1,
) {
    TextField(
        value,
        onValueChange,
        modifier,
        enabled,
        readOnly,
        textStyle,
        label,
        placeholder,
        leadingIcon,
        trailingIcon,
        prefix,
        suffix,
        supportingText,
        isError,
        visualTransformation,
        keyboardOptions,
        keyboardActions,
        singleLine,
        maxLines,
        minLines,
        shape = MaterialTheme.shapes.small,
        colors = fieldColors(),
    )
}

// The same for a value that also holds where the cursor is, for a field whose text is also changed from outside, such as by keys that add a piece at its end.
@Composable
fun AppTextField(
    value: TextFieldValue,
    onValueChange: (TextFieldValue) -> Unit,
    modifier: Modifier = Modifier,
    textStyle: TextStyle = LocalTextStyle.current,
    singleLine: Boolean = false,
    visualTransformation: VisualTransformation = VisualTransformation.None,
    keyboardOptions: KeyboardOptions = KeyboardOptions.Default,
    keyboardActions: KeyboardActions = KeyboardActions.Default,
) {
    TextField(
        value,
        onValueChange,
        modifier,
        textStyle = textStyle,
        singleLine = singleLine,
        visualTransformation = visualTransformation,
        keyboardOptions = keyboardOptions,
        keyboardActions = keyboardActions,
        shape = MaterialTheme.shapes.small,
        colors = fieldColors(),
    )
}

// The colors of the field: a wash of the accent with no line, lighter while typed in, and a red line when it is wrong.
@Composable
private fun fieldColors(): TextFieldColors {
    val rest = softFill()
    return TextFieldDefaults.colors(
        focusedContainerColor = softFill(lit = true),
        unfocusedContainerColor = rest,
        disabledContainerColor = rest.copy(alpha = rest.alpha / 2),
        errorContainerColor = rest,
        focusedIndicatorColor = Color.Transparent,
        unfocusedIndicatorColor = Color.Transparent,
        disabledIndicatorColor = Color.Transparent,
        errorIndicatorColor = MaterialTheme.colorScheme.error,
    )
}
