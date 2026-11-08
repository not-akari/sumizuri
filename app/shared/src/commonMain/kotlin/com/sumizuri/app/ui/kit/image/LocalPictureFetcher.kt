package com.sumizuri.app.ui.kit.image

import coil3.ImageLoader
import coil3.Uri
import coil3.decode.DataSource
import coil3.decode.ImageSource
import coil3.fetch.FetchResult
import coil3.fetch.Fetcher
import coil3.fetch.SourceFetchResult
import coil3.request.Options
import com.sumizuri.app.data.local.LocalPicture
import com.sumizuri.app.data.local.archiveSource
import com.sumizuri.app.data.local.localPictureOf
import com.sumizuri.app.data.local.renderPdfPage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.withContext
import okio.Buffer
import okio.FileSystem
import okio.Path.Companion.toPath
import okio.buffer

// Loads a picture that is on the device: a saved page of a chapter, or a page inside an archive such as a CBZ. The picture is decoded straight from its file, with no copy of it in memory first.
class LocalPictureFetcher(private val picture: LocalPicture, private val options: Options) : Fetcher {
    override suspend fun fetch(): FetchResult {
        val source = withContext(Dispatchers.IO) {
            when (picture) {
                is LocalPicture.File -> ImageSource(picture.path.toPath(), FileSystem.SYSTEM)

                is LocalPicture.PdfPage -> ImageSource(
                    Buffer().write(renderPdfPage(picture.pdf, picture.index)),
                    options.fileSystem,
                )

                is LocalPicture.Entry -> ImageSource(
                    archiveSource(picture.archive, picture.entry).buffer(),
                    options.fileSystem,
                )
            }
        }
        return SourceFetchResult(source, null, DataSource.DISK)
    }

    class Factory : Fetcher.Factory<Uri> {
        override fun create(data: Uri, options: Options, imageLoader: ImageLoader): Fetcher? {
            val picture = localPictureOf(data.toString()) ?: return null
            return LocalPictureFetcher(picture, options)
        }
    }
}
