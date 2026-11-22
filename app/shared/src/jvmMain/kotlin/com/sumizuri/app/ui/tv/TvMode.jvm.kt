package com.sumizuri.app.ui.tv

// A computer is never a TV, but the TV screens can be tried on one with -Dsumizuri.tv=true or SUMIZURI_TV=1.
actual fun isTvDevice(): Boolean = System.getProperty("sumizuri.tv") == "true" || System.getenv("SUMIZURI_TV") == "1"
