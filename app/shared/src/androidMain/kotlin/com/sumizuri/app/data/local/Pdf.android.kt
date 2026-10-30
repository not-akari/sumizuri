package com.sumizuri.app.data.local

import com.sumizuri.app.AndroidApp
import com.tom_roush.pdfbox.android.PDFBoxResourceLoader
import com.tom_roush.pdfbox.pdmodel.PDDocument
import com.tom_roush.pdfbox.text.PDFTextStripper
import java.io.File

actual fun pdfText(path: String): String {
    PDFBoxResourceLoader.init(AndroidApp.context)
    return PDDocument.load(File(path)).use { document ->
        PDFTextStripper().run {
            lineSeparator = " "
            paragraphEnd = "\n\n"
            pageEnd = ""
            getText(document).let(::tidiedPdfText)
        }
    }
}
