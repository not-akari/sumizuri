package com.sumizuri.app.data.local

// The pages of a PDF on the device are shown as pictures, as the pages of a comic, so the art and the layout of a light novel stay as printed.
expect fun pdfPageCount(path: String): Int

// One page of a PDF drawn as a JPEG, counted from 0. It is drawn only when the reader asks for that page.
expect fun renderPdfPage(path: String, index: Int): ByteArray
