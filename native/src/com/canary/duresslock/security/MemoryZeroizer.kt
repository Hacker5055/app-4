package com.canary.duresslock.security

import android.util.Log
import java.util.Arrays
import java.util.concurrent.ConcurrentHashMap

/**
 * MemoryZeroizer — Secure memory wiping for duress scenarios.
 *
 * Overwrites sensitive byte arrays with 0x00 to prevent memory forensics.
 * Tracks registered buffers and provides bulk zeroization on duress trigger.
 *
 * Critical: Uses Arrays.fill() + volatile write barrier to prevent
 * compiler optimization from eliding the wipe.
 */
object MemoryZeroizer {

    private const val TAG = "MemoryZeroizer"

    // Registry of sensitive buffers — keyed by alias/buffer ID
    private val bufferRegistry = ConcurrentHashMap<String, ByteArray>()

    // Volatile sentinel to prevent dead-code elimination of fill()
    @Volatile
    private var wipeCounter: Long = 0

    /**
     * Register a sensitive buffer for tracking.
     * The buffer will be zeroized when duress is triggered.
     */
    fun registerBuffer(bufferId: String, data: ByteArray) {
        bufferRegistry[bufferId] = data
        Log.d(TAG, "Buffer registered: $bufferId (${data.size} bytes)")
    }

    /**
     * Zeroize a specific buffer by ID.
     * Overwrites with 0x00 and removes from registry.
     */
    fun zeroizeBuffer(bufferId: String): Boolean {
        val buffer = bufferRegistry[bufferId]
        return if (buffer != null) {
            secureWipe(buffer)
            bufferRegistry.remove(bufferId)
            Log.d(TAG, "Buffer zeroized: $bufferId")
            true
        } else {
            Log.w(TAG, "Buffer not found for zeroization: $bufferId")
            false
        }
    }

    /**
     * Zeroize buffers associated with a specific alias.
     */
    fun zeroizeForAlias(alias: String) {
        val toRemove = bufferRegistry.keys.filter { it.contains(alias) || it.startsWith(alias) }
        for (key in toRemove) {
            zeroizeBuffer(key)
        }
        // Also wipe any buffer whose ID contains the alias prefix
        if (toRemove.isEmpty()) {
            Log.d(TAG, "No buffers found for alias: $alias")
        }
    }

    /**
     * BULK ZEROIZATION — Wipes ALL registered buffers.
     * Called during duress sequence after KeyStore purge.
     */
    fun zeroizeAll(): Boolean {
        return try {
            val count = bufferRegistry.size
            if (count == 0) {
                Log.d(TAG, "No buffers to zeroize — registry empty")
                return true
            }
            Log.w(TAG, "ZEROIZING $count buffers — duress wipe initiated")
            for ((id, buffer) in bufferRegistry) {
                secureWipe(buffer)
                Log.d(TAG, "Wiped: $id (${buffer.size} bytes -> 0x00)")
            }
            bufferRegistry.clear()

            // Force GC hint — encourage JVM to reclaim wiped arrays
            System.gc()

            Log.w(TAG, "ALL BUFFERS ZEROIZED — $count buffers wiped, registry cleared")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Bulk zeroization failed", e)
            false
        }
    }

    /**
     * Securely wipe a byte array.
     * Uses multi-pass overwrite to defeat cold-boot and memory dump attacks:
     *   Pass 1: 0x00
     *   Pass 2: 0xFF
     *   Pass 3: 0x00 (final)
     *
     * The volatile write prevents the compiler from optimizing away the fills.
     */
    fun secureWipe(data: ByteArray) {
        // Pass 1: zeros
        Arrays.fill(data, 0.toByte())
        wipeCounter++

        // Pass 2: ones
        Arrays.fill(data, 0xFF.toByte())
        wipeCounter++

        // Pass 3: zeros (final state)
        Arrays.fill(data, 0.toByte())
        wipeCounter++

        // Prevent dead-code elimination — read back one byte through volatile
        @Suppress("UNUSED_VARIABLE")
        val sentinel = data[0]
        wipeCounter += sentinel.toLong()
    }

    /**
     * Wipe a CharArray (for PIN/password handling).
     */
    fun secureWipe(data: CharArray) {
        Arrays.fill(data, '\u0000')
        wipeCounter++
        Arrays.fill(data, '\uFFFF')
        wipeCounter++
        Arrays.fill(data, '\u0000')
        wipeCounter++
    }

    /**
     * Wipe with explicit byte pattern — for testing verification.
     */
    fun wipeWithPattern(data: ByteArray, pattern: Byte) {
        Arrays.fill(data, pattern)
        wipeCounter++
    }

    fun registeredCount(): Int = bufferRegistry.size

    fun isBufferRegistered(bufferId: String): Boolean = bufferRegistry.containsKey(bufferId)
}
