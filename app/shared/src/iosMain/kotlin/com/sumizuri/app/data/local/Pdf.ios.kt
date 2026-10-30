package com.sumizuri.app.data.local

// ponytail: no PDF reader on the iPhone, the Suki releases do not build for it. PDFKit gives the words if that changes.
actual fun pdfText(path: String): String = error("PDF files are not read on this device")
