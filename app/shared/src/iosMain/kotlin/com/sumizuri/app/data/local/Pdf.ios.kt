package com.sumizuri.app.data.local

// PDF pages are not drawn on the iPhone yet. PDFKit can draw them.
actual fun pdfPageCount(path: String): Int = error("PDF files are not read on this device")

actual fun renderPdfPage(path: String, index: Int): ByteArray = error("PDF files are not read on this device")
