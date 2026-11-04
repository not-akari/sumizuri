package com.sumizuri.app.data.local

import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import java.io.ByteArrayOutputStream
import java.io.File

// How wide a page is drawn, in pixels, which fills the screen of a phone or a TV.
private const val PageWidth = 1400

private fun <T> pdf(path: String, use: (PdfRenderer) -> T): T = ParcelFileDescriptor
    .open(
        File(path),
        ParcelFileDescriptor.MODE_READ_ONLY,
    ).use { file -> PdfRenderer(file).use(use) }

actual fun pdfPageCount(path: String): Int = pdf(path) { it.pageCount }

actual fun renderPdfPage(path: String, index: Int): ByteArray = pdf(path) { renderer ->
    renderer.openPage(index).use { page ->
        val bitmap = Bitmap.createBitmap(PageWidth, PageWidth * page.height / page.width, Bitmap.Config.ARGB_8888)
        bitmap.eraseColor(Color.WHITE)
        page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
        ByteArrayOutputStream()
            .also {
                bitmap.compress(Bitmap.CompressFormat.JPEG, 90, it)
            }.toByteArray()
            .also { bitmap.recycle() }
    }
}
