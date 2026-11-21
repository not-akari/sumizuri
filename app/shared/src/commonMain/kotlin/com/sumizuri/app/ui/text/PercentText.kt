package com.sumizuri.app.ui.text

import androidx.compose.runtime.Composable
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.display_percent
import org.jetbrains.compose.resources.stringResource
import kotlin.math.roundToInt

// A part as a percent in the language of the screen, such as 0.6 as 60%.
@Composable
fun percentText(part: Float): String = stringResource(Res.string.display_percent, (part * 100).roundToInt())
