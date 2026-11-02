package com.sumizuri.app.feature.reader.view

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.ImageBitmap
import androidx.compose.ui.unit.dp
import coil3.PlatformContext
import coil3.compose.LocalPlatformContext
import coil3.request.CachePolicy
import coil3.request.SuccessResult
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.feature.reader.PageLoad
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.reader_page_failed
import com.sumizuri.app.source.model.Descramble
import com.sumizuri.app.ui.kit.art.InkCircularProgressIndicator
import com.sumizuri.app.ui.kit.cover.focus.cpuReadable
import com.sumizuri.app.ui.kit.image.ImageFit
import com.sumizuri.app.ui.kit.image.PageCache
import com.sumizuri.app.ui.kit.image.PageImages
import com.sumizuri.app.ui.kit.image.SlicedImage
import com.sumizuri.app.ui.kit.image.buildImageRequest
import com.sumizuri.app.ui.kit.image.cropBorders
import com.sumizuri.app.ui.kit.image.forgetFailedPicture
import com.sumizuri.app.ui.kit.image.onGraphicsMemory
import com.sumizuri.app.ui.kit.image.release
import com.sumizuri.app.ui.kit.image.sliceTall
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withPermit
import kotlinx.coroutines.withContext
import org.jetbrains.compose.resources.stringResource

// No slice is taller than this many pixels, which every graphics card can hold.
private const val SliceHeight = 2048

// Told once a page has drawn or failed, so the reader can keep its opening card up until there is something to see.
val LocalPageShown = staticCompositionLocalOf<() -> Unit> { {} }

// One picture page, loaded at its own size and cut into slices, so even a very tall strip is drawn sharp. A failed page loads again on a tap.
@Composable
fun PageImage(
    url: String,
    headers: Map<String, String>,
    number: Int,
    modifier: Modifier = Modifier,
    fit: ImageFit = ImageFit.Width,
    bias: Float = 0.5f,
    shape: Float? = null,
    onShape: ((Float) -> Unit)? = null,
    visibleRangePx: (() -> ClosedFloatingPointRange<Float>?)? = null,
    maxWidth: Int? = null,
    descramble: Descramble? = null,
    crop: Boolean = false,
) {
    val context = LocalPlatformContext.current
    val key = pageKey(url, headers, maxWidth, descramble, crop)
    var attempt by remember { mutableIntStateOf(0) }
    val load by produceState<PageLoad>(
        PageCache.get(key, nowMillis())?.let {
            PageLoad.Ready(it)
        } ?: PageLoad.Loading,
        key,
        attempt,
    ) {
        // A page shown a moment ago, or read ahead of the reader, comes straight from the cache.
        PageCache.get(key, nowMillis())?.let {
            value = PageLoad.Ready(it)
            return@produceState
        }
        value = PageLoad.Loading
        // A tap to load again asks at once, even for a page that failed a moment ago.
        if (attempt > 0) forgetFailedPicture(url)
        value =
            readPage(context, url, headers, maxWidth, descramble, crop)?.let { PageLoad.Ready(it) } ?: PageLoad.Failed
    }
    val shownNow = LocalPageShown.current
    LaunchedEffect(load is PageLoad.Loading) { if (load !is PageLoad.Loading) shownNow() }
    when (val state = load) {
        PageLoad.Loading -> Waiting(modifier, fit, shape) { InkCircularProgressIndicator(strokeWidth = 2.dp) }

        PageLoad.Failed -> Waiting(modifier.clickable { attempt++ }, fit, shape) {
            Text(stringResource(Res.string.reader_page_failed, number), color = MaterialTheme.colorScheme.error)
        }

        is PageLoad.Ready -> {
            SlicedImage(state.slices, modifier, fit, bias, visibleRangePx)
            LaunchedEffect(
                state,
            ) { onShape?.invoke(state.slices.sumOf { it.height }.toFloat() / state.slices.first().width) }
        }
    }
}

// The key a page is kept under: its address, the width it is read at and how it is shuffled. A shuffled page keeps its own size, since the tiles are cut by the size it came in.
private fun pageKey(
    url: String,
    headers: Map<String, String>,
    maxWidth: Int?,
    descramble: Descramble?,
    crop: Boolean,
): String = buildString {
    append(url)
    append('|')
    append(if (descramble == null) maxWidth else null)
    append('|')
    headers.toList().sortedBy { it.first }.forEach { (name, value) ->
        append(name.length)
        append(':')
        append(name)
        append(value.length)
        append(':')
        append(value)
    }
    append('|')
    descramble?.let {
        append(it.cols)
        append('x')
        append(it.rows)
        append(':')
        it.order.joinTo(this, ",")
    }
    if (crop) append("|crop")
}

private class PageLoadLock(val mutex: Mutex = Mutex(), var users: Int = 0)
private val pageLoadLocks = mutableMapOf<String, PageLoadLock>()

// Work for pages ahead of the reader goes one picture at a time. A page is read at its full size, so several at once would fill the memory and keep the processor from the page that is on the screen.
object PageWork {
    val ahead = Semaphore(1)
}

// Reads a page at its own size, cuts it into slices and keeps them in the page cache, or gives what the cache has. Null when it could not be read. A page read ahead of the reader waits its turn, and a page on the screen does not.
suspend fun readPage(
    context: PlatformContext,
    url: String,
    headers: Map<String, String>,
    maxWidth: Int?,
    descramble: Descramble?,
    crop: Boolean = false,
    ahead: Boolean = false,
): List<ImageBitmap>? {
    val key = pageKey(url, headers, maxWidth, descramble, crop)
    PageCache.get(key, nowMillis())?.let { return it }
    val lock = pageLoadLocks.getOrPut(key) { PageLoadLock() }.also { it.users++ }
    var locked = false
    try {
        lock.mutex.lock()
        locked = true
        PageCache.get(key, nowMillis())?.let { return it }
        if (!ahead) return readNow(context, url, headers, maxWidth, descramble, crop)
        return PageWork.ahead.withPermit {
            // The page may have been read while this one waited.
            PageCache.get(key, nowMillis()) ?: readNow(context, url, headers, maxWidth, descramble, crop)
        }
    } finally {
        if (locked) lock.mutex.unlock()
        lock.users--
        if (lock.users == 0 && pageLoadLocks[key] === lock) pageLoadLocks.remove(key)
    }
}

private suspend fun readNow(
    context: PlatformContext,
    url: String,
    headers: Map<String, String>,
    maxWidth: Int?,
    descramble: Descramble?,
    crop: Boolean,
): List<ImageBitmap>? {
    val key = pageKey(url, headers, maxWidth, descramble, crop)
    val limit = if (descramble == null) maxWidth else null
    // The whole picture is not kept in the memory cache, because the slices are what the page keeps.
    val request = buildImageRequest(context, url, headers, original = true, maxWidth = limit)
        .newBuilder()
        .memoryCachePolicy(CachePolicy.DISABLED)
        .cpuReadable()
        .build()
    val result = PageImages.get(context).execute(request) as? SuccessResult ?: return null
    val slices = withContext(Dispatchers.Default) {
        result.image
            .sliceTall(SliceHeight, descramble)
            .let { cut ->
                if (crop) {
                    cropBorders(cut, SliceHeight).also { out ->
                        if (out !==
                            cut
                        ) {
                            cut.release()
                        }
                    }
                } else {
                    cut
                }
            }
            // The panels are found while the picture can still be read, for the panel by panel reading.
            .also { cut ->
                if (PagePanels.wanted &&
                    cut.size == 1
                ) {
                    PagePanels.put(panelKey(url, crop), runCatching { findPanels(cut[0]) }.getOrDefault(emptyList()))
                }
            }.onGraphicsMemory()
    }
    if (slices.isEmpty()) return null
    PageCache.put(key, slices, nowMillis())
    return slices
}

// A page in a long scroll waits in a box of fixed height, or in the height it is known to have, and a page of its own screen waits in the whole screen.
@Composable
private fun Waiting(modifier: Modifier, fit: ImageFit, shape: Float?, content: @Composable () -> Unit) {
    val size = when {
        fit != ImageFit.Width -> modifier.fillMaxSize()
        shape != null -> modifier.fillMaxWidth().aspectRatio(1f / shape)
        else -> modifier.fillMaxWidth().height(360.dp)
    }
    Box(size, contentAlignment = Alignment.Center) { content() }
}
