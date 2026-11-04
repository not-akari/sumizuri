package com.sumizuri.app.data.local

// ponytail: no PDF drawing on the iPhone, the Suki releases do not build for it. PDFKit draws the pages if that changes.
actual fun pdfPageCount(path: String): Int = error("PDF files are not read on this device")

actual fun renderPdfPage(path: String, index: Int): ByteArray = error("PDF files are not read on this device")
