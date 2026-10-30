package com.sumizuri.app.data.local

import java.io.File
import org.apache.pdfbox.Loader
import org.apache.pdfbox.text.PDFTextStripper

actual fun pdfText(path: String): String = Loader.loadPDF(File(path)).use { document ->
    PDFTextStripper().run {
        lineSeparator = " "
        paragraphEnd = "\n\n"
        pageEnd = ""
        getText(document).let(::tidiedPdfText)
    }
}
