package com.sumizuri.app.data.pair

// A TV waiting on the home network for one phone to send it a package. The address is where a phone on the same network reaches it.
interface PairListener {
    val address: String

    // Waits for the one post to the path given and gives its body, answering any other with a refusal.
    suspend fun receive(path: String): ByteArray

    fun close()
}

// Starts listening on a free port of the home network, or gives null where that cannot be done, such as with no network.
expect fun openPairListener(): PairListener?
