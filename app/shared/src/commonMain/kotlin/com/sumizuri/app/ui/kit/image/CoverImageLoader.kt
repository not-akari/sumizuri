package com.sumizuri.app.ui.kit.image

import coil3.ImageLoader
import coil3.PlatformContext
import coil3.SingletonImageLoader
import coil3.disk.DiskCache
import coil3.memory.MemoryCache
import coil3.network.ktor3.KtorNetworkFetcherFactory
import com.sumizuri.app.source.host.net.ImageHost
import io.ktor.client.HttpClient
import okio.FileSystem

// One network client for the covers and the pages, so pictures from the same site reuse their connections.
private val pictureClient = lazy { HttpClient() }

// The most memory the covers may take, whatever the share is. A cover is drawn at the size it is shown, a few hundred kilobytes, so this holds several hundred.
private const val MaxMemoryBytes = 128L * 1024 * 1024

// One loader for the whole app, with a memory cache and a disk cache so a cover is downloaded once, and a way past bot checks.
fun coverImageLoader(
    context: PlatformContext,
    images: ImageHost,
    diskMegabytes: Int = 256,
    memoryPercent: Int = 15,
): ImageLoader = ImageLoader
    .Builder(context)
    .components {
        // Pictures on the device, such as saved pages and pages inside archives.
        add(LocalPictureFetcher.Factory())
        add(GuardedImageFetcher.Factory(images, KtorNetworkFetcherFactory(httpClient = { pictureClient.value })))
        addSharpDecoder()
    }
    // The share of the memory the person chose, but never more than a fixed amount, since a share of a large heap would hold gigabytes of covers.
    .memoryCache {
        MemoryCache
            .Builder()
            .maxSizeBytes(
                minOf(coverMemoryBaseMb(context).toLong() * 1024 * 1024 * memoryPercent / 100, MaxMemoryBytes),
            ).build()
    }.diskCache {
        DiskCache
            .Builder()
            .directory(FileSystem.SYSTEM_TEMPORARY_DIRECTORY.resolve("sumizuri_covers"))
            .maxSizeBytes(diskMegabytes * 1024L * 1024)
            .build()
    }.build()

// The loader of the pages of the reader. It has a disk cache of its own, so reading long chapters does not push the covers out of theirs, and no memory cache, since the reader keeps its pages cut up in the page cache.
fun pageImageLoader(context: PlatformContext, images: ImageHost, diskMegabytes: Int = 256): ImageLoader = ImageLoader
    .Builder(context)
    .components {
        add(LocalPictureFetcher.Factory())
        add(GuardedImageFetcher.Factory(images, KtorNetworkFetcherFactory(httpClient = { pictureClient.value })))
        addSharpDecoder()
    }.memoryCache(null)
    .diskCache {
        DiskCache
            .Builder()
            .directory(FileSystem.SYSTEM_TEMPORARY_DIRECTORY.resolve("sumizuri_pages"))
            .maxSizeBytes(diskMegabytes * 1024L * 1024)
            .build()
    }.build()

// The page loader in use, set together with the cover loader. Before it is set the pages use the cover loader.
object PageImages {
    private var current: ImageLoader? = null

    fun set(loader: ImageLoader) {
        current = loader
    }

    // Lets go of a loader that is being shut down, unless a newer one took its place already.
    fun release(loader: ImageLoader) {
        if (current === loader) current = null
    }

    fun get(context: PlatformContext): ImageLoader = current ?: SingletonImageLoader.get(context)
}
