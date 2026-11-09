package com.sumizuri.app.data.local

import org.apache.pdfbox.Loader
import org.apache.pdfbox.rendering.PDFRenderer
import java.io.ByteArrayOutputStream
import java.io.File
import javax.imageio.ImageIO

// How sharp a page is drawn: 150 dots an inch fills a screen and reads well.
private const val PageDpi = 150f

actual fun pdfPageCount(path: String): Int = Loader.loadPDF(File(path)).use { it.numberOfPages }

// The file is opened again for each page, so only the page on screen is held in memory.
actual fun renderPdfPage(path: String, index: Int): ByteArray = Loader.loadPDF(File(path)).use { document ->
    val picture = PDFRenderer(document).renderImageWithDPI(index, PageDpi)
    ByteArrayOutputStream().also { ImageIO.write(picture, "jpg", it) }.toByteArray()
}
