package com.sumizuri.app.feature.comments

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.ThumbUp
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.comments_sort_newest
import com.sumizuri.app.shared.resources.comments_sort_oldest
import com.sumizuri.app.shared.resources.comments_sort_top
import com.sumizuri.app.shared.resources.comments_spoiler
import com.sumizuri.app.source.model.CommentSort
import com.sumizuri.app.source.model.SourceComment
import com.sumizuri.app.ui.kit.image.imageRequest
import com.sumizuri.app.ui.text.agoText
import com.sumizuri.app.ui.text.compactCount
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.stringResource

// Who wrote a comment and when, how many liked it, and the words, which can be selected and copied. A spoiler stays hidden until it is tapped.
@Composable
internal fun CommentBody(comment: SourceComment, avatar: Dp) {
    Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        Box(
            Modifier.size(avatar).clip(CircleShape).background(MaterialTheme.colorScheme.surfaceContainerHighest),
            contentAlignment = Alignment.Center,
        ) {
            Icon(Icons.Outlined.Person, null, Modifier.size(avatar * 0.55f), tint = MaterialTheme.colorScheme.outline)
            comment.avatarUrl?.let {
                AsyncImage(
                    imageRequest(it, maxWidth = 96),
                    null,
                    Modifier.size(avatar),
                    contentScale = ContentScale.Crop,
                )
            }
        }
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    comment.author,
                    Modifier.weight(1f, fill = false),
                    style = MaterialTheme.typography.labelLarge,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                )
                comment.postedAt?.let {
                    Text(
                        agoText(it),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.outline,
                        maxLines = 1,
                    )
                }
                comment.likes?.takeIf { it > 0 }?.let { likes ->
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(3.dp),
                    ) {
                        Icon(
                            Icons.Outlined.ThumbUp,
                            null,
                            Modifier.size(13.dp),
                            tint = MaterialTheme.colorScheme.outline,
                        )
                        Text(
                            compactCount(likes),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.outline,
                        )
                    }
                }
            }
            var revealed by rememberSaveable(comment.key()) { mutableStateOf(!comment.spoiler) }
            if (revealed) {
                SelectionContainer { Text(comment.text, style = MaterialTheme.typography.bodyMedium) }
            } else {
                Row(
                    Modifier
                        .clip(MaterialTheme.shapes.small)
                        .background(MaterialTheme.colorScheme.surfaceContainerHighest)
                        .clickable { revealed = true }
                        .padding(horizontal = 10.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                ) {
                    Icon(
                        Icons.Outlined.VisibilityOff,
                        null,
                        Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.outline,
                    )
                    Text(
                        stringResource(Res.string.comments_spoiler),
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.outline,
                    )
                }
            }
        }
    }
}

@Composable
internal fun SmallButton(text: String, onClick: () -> Unit) {
    TextButton(onClick, contentPadding = PaddingValues(horizontal = 8.dp, vertical = 0.dp)) {
        Text(text, style = MaterialTheme.typography.labelLarge)
    }
}

@Composable
internal fun Quiet(text: String) {
    Text(
        text,
        Modifier.padding(vertical = 24.dp),
        style = MaterialTheme.typography.bodyMedium,
        color = MaterialTheme.colorScheme.outline,
    )
}

// The name of an order of comments, for the tabs that pick it.
internal fun sortLabel(sort: CommentSort): StringResource = when (sort) {
    CommentSort.Newest -> Res.string.comments_sort_newest
    CommentSort.Oldest -> Res.string.comments_sort_oldest
    CommentSort.Top -> Res.string.comments_sort_top
}
