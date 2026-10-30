package com.sumizuri.app.data.local

// The words of a PDF on the device, as paragraphs with blank lines between them. A PDF of scanned pictures has none.
expect fun pdfText(path: String): String
