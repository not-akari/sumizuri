@file:OptIn(ExperimentalForeignApi::class, BetaInteropApi::class)

package com.sumizuri.app.data.account

import com.sumizuri.app.ui.toByteArray
import com.sumizuri.sync.core.SyncCrypto
import kotlinx.cinterop.BetaInteropApi
import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.MemScope
import kotlinx.cinterop.addressOf
import kotlinx.cinterop.alloc
import kotlinx.cinterop.allocArrayOf
import kotlinx.cinterop.convert
import kotlinx.cinterop.memScoped
import kotlinx.cinterop.ptr
import kotlinx.cinterop.reinterpret
import kotlinx.cinterop.usePinned
import kotlinx.cinterop.value
import platform.CoreFoundation.CFDictionaryCreate
import platform.CoreFoundation.CFDictionaryRef
import platform.CoreFoundation.CFStringRef
import platform.CoreFoundation.CFTypeRef
import platform.CoreFoundation.CFTypeRefVar
import platform.CoreFoundation.kCFAllocatorDefault
import platform.CoreFoundation.kCFBooleanTrue
import platform.Foundation.CFBridgingRelease
import platform.Foundation.CFBridgingRetain
import platform.Foundation.NSData
import platform.Foundation.NSFileManager
import platform.Foundation.NSFileProtectionComplete
import platform.Foundation.NSFileProtectionKey
import platform.Foundation.create
import platform.Security.SecItemAdd
import platform.Security.SecItemCopyMatching
import platform.Security.errSecSuccess
import platform.Security.kSecAttrAccessible
import platform.Security.kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
import platform.Security.kSecAttrAccount
import platform.Security.kSecAttrService
import platform.Security.kSecClass
import platform.Security.kSecClassGenericPassword
import platform.Security.kSecMatchLimit
import platform.Security.kSecMatchLimitOne
import platform.Security.kSecReturnData
import platform.Security.kSecValueData

// Where the key is kept in the Keychain.
private const val Service = "com.sumizuri.app"
private const val Account = "device-secret"

// What the key locks, said with every secret so one made for something else never opens.
private const val Purpose = "sumizuri device secret v1"
private const val KeyBytes = 32

// A key in the Keychain of the system, made the first time it is needed, locks each secret. The key stays on this device, is never in a backup of the phone, and can be read once the phone was unlocked after it started. Where the Keychain cannot be used, as in an app installed without a signature, nothing is sealed and the file is only kept private.
actual object DeviceSecret {
    private val key: ByteArray? by lazy { runCatching { savedKey() ?: newKey() }.getOrNull() }

    actual val canSeal: Boolean get() = key != null

    actual fun seal(bytes: ByteArray): ByteArray? = key?.let {
        runCatching { SyncCrypto.lock(it, bytes, Purpose) }.getOrNull()
    }

    actual fun open(bytes: ByteArray): ByteArray? = key?.let { SyncCrypto.unlock(it, bytes, Purpose) }

    actual fun keepPrivate(file: String) {
        NSFileManager.defaultManager.setAttributes(
            mapOf(NSFileProtectionKey to NSFileProtectionComplete),
            ofItemAtPath = file,
            error = null,
        )
    }

    // The key the Keychain holds, or null when it holds none yet.
    private fun savedKey(): ByteArray? = memScoped {
        val service = CFBridgingRetain(Service)
        val account = CFBridgingRetain(Account)
        try {
            val query = dictionaryOf(
                kSecClass to kSecClassGenericPassword,
                kSecAttrService to service,
                kSecAttrAccount to account,
                kSecReturnData to kCFBooleanTrue,
                kSecMatchLimit to kSecMatchLimitOne,
            )
            val found = alloc<CFTypeRefVar>()
            val status = SecItemCopyMatching(query, found.ptr)
            CFBridgingRelease(query)
            if (status != errSecSuccess) return@memScoped null
            (CFBridgingRelease(found.value) as? NSData)?.toByteArray()?.takeIf { it.size == KeyBytes }
        } finally {
            CFBridgingRelease(service)
            CFBridgingRelease(account)
        }
    }

    // Makes a key and puts it in the Keychain, or gives null when the Keychain does not take it.
    private fun newKey(): ByteArray? = memScoped {
        val made = SyncCrypto.randomBytes(KeyBytes)
        val data = made.usePinned { NSData.create(bytes = it.addressOf(0), length = made.size.convert()) }
        val service = CFBridgingRetain(Service)
        val account = CFBridgingRetain(Account)
        val value = CFBridgingRetain(data)
        try {
            val item = dictionaryOf(
                kSecClass to kSecClassGenericPassword,
                kSecAttrService to service,
                kSecAttrAccount to account,
                kSecAttrAccessible to kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
                kSecValueData to value,
            )
            val status = SecItemAdd(item, null)
            CFBridgingRelease(item)
            if (status == errSecSuccess) made else null
        } finally {
            CFBridgingRelease(service)
            CFBridgingRelease(account)
            CFBridgingRelease(value)
        }
    }

    // A dictionary of the system from the pairs given, which the caller lets go of.
    private fun MemScope.dictionaryOf(vararg pairs: Pair<CFStringRef?, CFTypeRef?>): CFDictionaryRef? {
        val keys = allocArrayOf(*pairs.map { it.first }.toTypedArray())
        val values = allocArrayOf(*pairs.map { it.second }.toTypedArray())
        return CFDictionaryCreate(
            kCFAllocatorDefault,
            keys.reinterpret(),
            values.reinterpret(),
            pairs.size.convert(),
            null,
            null,
        )
    }
}
