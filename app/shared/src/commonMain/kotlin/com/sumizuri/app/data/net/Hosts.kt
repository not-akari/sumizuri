package com.sumizuri.app.data.net

// The host of an address in small letters, without a user, a port or brackets, or the text itself when it is only a host. Empty when there is none.
fun hostOf(url: String): String {
    val authority = url
        .substringAfter("://")
        .substringBefore('/')
        .substringBefore('?')
        .substringBefore('#')
    val withoutUser = authority.substringAfterLast('@')
    return if (withoutUser.startsWith("[")) {
        withoutUser.substringAfter('[').substringBefore(']')
    } else {
        withoutUser.substringBefore(':')
    }.trim().lowercase()
}

// The name of the site of an address as a person reads it, the host without a leading www.
fun siteNameOf(url: String): String = hostOf(url).removePrefix("www.")
