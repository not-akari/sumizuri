package com.sumizuri.app.ui.language

import platform.Foundation.*

// The words are looked up in the languages the app asks for, which the system also reads when the app starts, so the choice shows at once and stays for the next start. null goes back to the languages of the system.
actual fun applyAppLanguage(code: String?) {
    val defaults = NSUserDefaults.standardUserDefaults
    if (code ==
        null
    ) {
        defaults.removeObjectForKey("AppleLanguages")
    } else {
        defaults.setObject(listOf(code), forKey = "AppleLanguages")
    }
}
