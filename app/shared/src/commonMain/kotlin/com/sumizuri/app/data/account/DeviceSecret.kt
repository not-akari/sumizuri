package com.sumizuri.app.data.account

// Locks small secrets with a key of the system that only this user on this device can use: the Android Keystore on an Android phone, the Keychain on an iPhone, the data protection of Windows, and the key store of the system on Linux and a Mac. Where the system has none, sealing gives null and the file is only kept private.
expect object DeviceSecret {
    // Whether secrets are sealed on this device, for saying so on the pages that keep them.
    val canSeal: Boolean

    fun seal(bytes: ByteArray): ByteArray?

    fun open(bytes: ByteArray): ByteArray?

    // Lets only the person who owns the file read it, where the system allows that.
    fun keepPrivate(file: String)
}
