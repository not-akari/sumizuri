package com.sumizuri.app.ui.kit.art

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.hoverable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.interaction.collectIsPressedAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.IntrinsicSize
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.automirrored.rounded.ArrowForward
import androidx.compose.material.icons.outlined.AutoStories
import androidx.compose.material.icons.outlined.Info
import androidx.compose.material.icons.outlined.Movie
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.kind_anime
import com.sumizuri.app.shared.resources.kind_manga
import com.sumizuri.app.shared.resources.kind_novel
import com.sumizuri.app.shared.resources.setup_feature_anime_hint
import com.sumizuri.app.shared.resources.setup_feature_manga_hint
import com.sumizuri.app.shared.resources.setup_feature_novel_hint
import com.sumizuri.app.ui.kit.card.cardFill
import org.jetbrains.compose.resources.stringResource
import kotlin.math.PI
import kotlin.math.sin

// The large controls of the setup and of the first steps of the app: buttons that give under a press, lines with an icon, notices, and floating cards for what the app holds. The button that moves on, which grows a little under the mouse, gives under a press, and leans its arrow forward.
@Composable
internal fun MainButton(
    text: String,
    onClick: () -> Unit,
    icon: ImageVector? = Icons.AutoMirrored.Rounded.ArrowForward,
    enabled: Boolean = true,
    danger: Boolean = false,
) {
    val source = remember { MutableInteractionSource() }
    val pressed by source.collectIsPressedAsState()
    val hovered by source.collectIsHoveredAsState()
    val scale by animateFloatAsState(
        if (pressed) {
            0.95f
        } else if (hovered && enabled) {
            1.03f
        } else {
            1f
        },
        spring(stiffness = 600f),
        label = "scale",
    )
    val nudge by animateDpAsState(if (hovered && enabled) 4.dp else 0.dp, label = "nudge")
    val colors = if (danger) {
        ButtonDefaults.buttonColors(
            containerColor = MaterialTheme.colorScheme.error,
            contentColor = MaterialTheme.colorScheme.onError,
        )
    } else {
        ButtonDefaults.buttonColors()
    }
    Button(
        onClick,
        Modifier.height(46.dp).graphicsLayer {
            scaleX = scale
            scaleY = scale
        },
        enabled = enabled,
        colors = colors,
        interactionSource = source,
        contentPadding = PaddingValues(horizontal = 26.dp),
    ) {
        Text(text, fontWeight = FontWeight.SemiBold)
        if (icon != null) {
            Spacer(Modifier.width(8.dp))
            Icon(icon, null, Modifier.size(18.dp).offset(x = nudge))
        }
    }
}

// The quieter button beside it, with the same give under a press.
@Composable
internal fun QuietButton(text: String, onClick: () -> Unit, icon: ImageVector? = null, enabled: Boolean = true) {
    val source = remember { MutableInteractionSource() }
    val pressed by source.collectIsPressedAsState()
    val scale by animateFloatAsState(if (pressed) 0.95f else 1f, spring(stiffness = 600f), label = "scale")
    OutlinedButton(
        onClick,
        Modifier.height(46.dp).graphicsLayer {
            scaleX = scale
            scaleY = scale
        },
        enabled = enabled,
        interactionSource = source,
        contentPadding = PaddingValues(horizontal = 22.dp),
    ) {
        if (icon != null) {
            Icon(icon, null, Modifier.size(18.dp))
            Spacer(Modifier.width(8.dp))
        }
        Text(text)
    }
}

// A line with an icon in a soft square, as the rows of the settings have.
@Composable
internal fun Fact(icon: ImageVector, text: String, modifier: Modifier = Modifier) {
    Row(modifier, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Box(
            Modifier
                .size(
                    34.dp,
                ).clip(RoundedCornerShape(10.dp))
                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)),
            contentAlignment = Alignment.Center,
        ) {
            Icon(icon, null, Modifier.size(18.dp), tint = MaterialTheme.colorScheme.primary)
        }
        Text(text, style = MaterialTheme.typography.bodyLarge)
    }
}

// A card that tells something to keep in mind, such as the app being open, or how something went, in the color that says so.
@Composable
internal fun Notice(
    text: String,
    modifier: Modifier = Modifier,
    icon: ImageVector = Icons.Outlined.Info,
    tint: Color = MaterialTheme.colorScheme.primary,
    fill: Color = MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.55f),
) {
    Row(
        modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(fill)
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Icon(icon, null, Modifier.size(20.dp), tint = tint)
        Text(text, style = MaterialTheme.typography.bodyMedium)
    }
}

// One of the three things the app holds, in a card that floats a little on its own, out of step with the others, and lifts under the mouse.
@Composable
internal fun FeatureTile(icon: ImageVector, title: String, hint: String, order: Int, modifier: Modifier) {
    val source = remember { MutableInteractionSource() }
    val hovered by source.collectIsHoveredAsState()
    val lift by animateDpAsState(
        if (hovered) 6.dp else 0.dp,
        spring(dampingRatio = 0.6f, stiffness = 300f),
        label = "lift",
    )
    val transition = rememberInfiniteTransition(label = "float")
    val float by transition.animateFloat(
        0f,
        1f,
        infiniteRepeatable(tween(3_600, easing = LinearEasing)),
        label = "float",
    )
    val colors = MaterialTheme.colorScheme
    val shape = RoundedCornerShape(16.dp)
    Column(
        modifier
            .rise(order)
            .graphicsLayer {
                translationY =
                    -lift.toPx() + sin((float + order * 0.33f) * 2f * PI.toFloat()) * 2.dp.toPx()
            }.clip(shape)
            .background(cardFill(hovered))
            .border(1.dp, colors.outlineVariant.copy(alpha = if (hovered) 0.9f else 0.5f), shape)
            .hoverable(source)
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Icon(icon, null, Modifier.size(26.dp), tint = colors.primary)
        Spacer(Modifier.height(6.dp))
        Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        Text(
            hint,
            style = MaterialTheme.typography.bodySmall,
            color = colors.onSurfaceVariant,
            maxLines = 3,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

// The three things the app holds side by side, manga, novels and anime, each in a floating card, rising in from the order given.
@Composable
internal fun KindTiles(order: Int, modifier: Modifier = Modifier) {
    Row(modifier.fillMaxWidth().height(IntrinsicSize.Max), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        FeatureTile(
            Icons.AutoMirrored.Outlined.MenuBook,
            stringResource(Res.string.kind_manga),
            stringResource(Res.string.setup_feature_manga_hint),
            order,
            Modifier.weight(1f).fillMaxHeight(),
        )
        FeatureTile(
            Icons.Outlined.AutoStories,
            stringResource(Res.string.kind_novel),
            stringResource(Res.string.setup_feature_novel_hint),
            order + 1,
            Modifier.weight(1f).fillMaxHeight(),
        )
        FeatureTile(
            Icons.Outlined.Movie,
            stringResource(Res.string.kind_anime),
            stringResource(Res.string.setup_feature_anime_hint),
            order + 2,
            Modifier.weight(1f).fillMaxHeight(),
        )
    }
}

// A small bar of the accent that stretches out for what is chosen and shrinks back for the rest, to a dot or to nothing, as the steps of the first run and the tabs mark the one that is open. Those already passed keep the accent.
@Composable
fun StretchDot(
    active: Boolean,
    modifier: Modifier = Modifier,
    done: Boolean = false,
    idle: Dp = 10.dp,
    wide: Dp = 28.dp,
    height: Dp = 8.dp,
) {
    val width by animateDpAsState(
        if (active) wide else idle,
        spring(dampingRatio = 0.6f, stiffness = 300f),
        label = "dot",
    )
    val color by animateColorAsState(
        if (active ||
            done
        ) {
            MaterialTheme.colorScheme.primary
        } else {
            MaterialTheme.colorScheme.outline.copy(alpha = 0.35f)
        },
        label = "dot color",
    )
    Box(
        modifier
            .height(height)
            .width(width)
            .clip(CircleShape)
            .background(color),
    )
}
