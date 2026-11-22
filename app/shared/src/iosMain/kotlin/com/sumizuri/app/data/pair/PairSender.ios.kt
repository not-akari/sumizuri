package com.sumizuri.app.data.pair

// An iPhone does not send to a TV yet.
actual suspend fun sendPair(link: PairLink, body: ByteArray): Boolean = false
