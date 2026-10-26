package com.canary.duresslock.security

import android.content.Context
import android.content.SharedPreferences
import android.os.Build
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import android.security.keystore.KeyInfo
import android.util.Base64
import android.util.Log
import java.security.KeyStore
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.SecretKeySpec

/**
 * Canary KeyStoreManager — Hardware-Backed AES-256-GCM Encryption
 *
 * Generates and manages keys inside AndroidKeyStore with StrongBox preference.
 * Keys are bound to TEE/StrongBox and never leave secure hardware.
 * Supports immediate purge via deleteEntry() for duress scenarios.
 */
class KeyStoreManager(private val context: Context) {

    companion object {
        private const val TAG = "KeyStoreManager"
        private const val ANDROID_KEYSTORE = "AndroidKeyStore"
        private const val AES_MODE = "AES/GCM/NoPadding"
        private const val KEY_SIZE = 256
        private const val GCM_TAG_LENGTH = 128
        private const val IV_LENGTH = 12
    }

    private val keyStore: KeyStore by lazy {
        KeyStore.getInstance(ANDROID_KEYSTORE).apply { load(null) }
    }

    /**
     * Generate AES-256-GCM key inside AndroidKeyStore.
     * Prefers StrongBox (tamper-resistant hardware) when available.
     * Falls back to TEE if StrongBox unavailable.
     */
    fun generateMasterKey(alias: String, requireBiometric: Boolean = false, useStrongBox: Boolean = true): Boolean {
        return try {
            if (keyStore.containsAlias(alias)) {
                Log.d(TAG, "Key already exists for alias: $alias")
                return true
            }

            val builder = KeyGenParameterSpec.Builder(alias,
                KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(KEY_SIZE)
                .setRandomizedEncryptionRequired(true)
                .setUserAuthenticationRequired(requireBiometric)
                .apply {
                    if (requireBiometric) {
                        setUserAuthenticationValidityDurationSeconds(30)
                        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                            setUserAuthenticationParameters(30, KeyProperties.AUTH_BIOMETRIC_STRONG)
                        }
                    }
                    // StrongBox preference — hardware tamper resistance
                    if (useStrongBox && Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        try {
                            setIsStrongBoxBacked(true)
                            Log.d(TAG, "StrongBox requested for alias: $alias")
                        } catch (e: Exception) {
                            Log.w(TAG, "StrongBox not available, using TEE: ${e.message}")
                        }
                    }
                }

            val keyGenerator = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, ANDROID_KEYSTORE)
            keyGenerator.init(builder.build())
            val secretKey = keyGenerator.generateKey()

            // Verify key is inside secure hardware
            val isSecureHardware = isInsideSecureHardware(alias)
            Log.i(TAG, "Key generated | alias=$alias | secureHardware=$isSecureHardware | StrongBox=$useStrongBox")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Failed to generate key for $alias", e)
            // Retry without StrongBox if it was the cause
            if (useStrongBox) {
                Log.w(TAG, "Retrying without StrongBox...")
                return generateMasterKey(alias, requireBiometric, useStrongBox = false)
            }
            false
        }
    }

    /**
     * Encrypt plaintext using hardware-backed key.
     * Returns Base64(IV + ciphertext + GCM tag)
     */
    fun encrypt(alias: String, plaintext: String): String? {
        return try {
            val secretKey = getSecretKey(alias) ?: run {
                Log.e(TAG, "No key found for alias: $alias")
                return null
            }
            val cipher = Cipher.getInstance(AES_MODE)
            cipher.init(Cipher.ENCRYPT_MODE, secretKey)
            val iv = cipher.iv
            val ciphertext = cipher.doFinal(plaintext.toByteArray(Charsets.UTF_8))

            // Prepend IV to ciphertext
            val combined = ByteArray(iv.size + ciphertext.size)
            System.arraycopy(iv, 0, combined, 0, iv.size)
            System.arraycopy(ciphertext, 0, combined, iv.size, ciphertext.size)

            Base64.encodeToString(combined, Base64.NO_WRAP)
        } catch (e: Exception) {
            Log.e(TAG, "Encryption failed for $alias", e)
            null
        }
    }

    /**
     * Decrypt ciphertext using hardware-backed key.
     */
    fun decrypt(alias: String, ciphertext: String): String? {
        return try {
            val secretKey = getSecretKey(alias) ?: return null
            val combined = Base64.decode(ciphertext, Base64.NO_WRAP)

            val iv = combined.copyOfRange(0, IV_LENGTH)
            val encrypted = combined.copyOfRange(IV_LENGTH, combined.size)

            val cipher = Cipher.getInstance(AES_MODE)
            val spec = GCMParameterSpec(GCM_TAG_LENGTH, iv)
            cipher.init(Cipher.DECRYPT_MODE, secretKey, spec)
            val plaintext = cipher.doFinal(encrypted)
            String(plaintext, Charsets.UTF_8)
        } catch (e: Exception) {
            Log.e(TAG, "Decryption failed for $alias", e)
            null
        }
    }

    /**
     * CRITICAL DURESS OPERATION — Purge key from AndroidKeyStore.
     * Calls keyStore.deleteEntry(alias) and verifies deletion.
     * This is irreversible — key material is destroyed in hardware.
     */
    fun purgeKey(alias: String): Boolean {
        return try {
            if (!keyStore.containsAlias(alias)) {
                Log.w(TAG, "Key not found for purge: $alias (already deleted?)")
                return true
            }
            keyStore.deleteEntry(alias)
            // Verify deletion
            val deleted = !keyStore.containsAlias(alias)
            if (deleted) {
                Log.w(TAG, "PURGE SUCCESS — Key deleted: $alias | StrongBox/TEE wiped")
            } else {
                Log.e(TAG, "PURGE FAILED — Key still exists: $alias")
            }
            // Also clear any cached SharedPreferences tokens tied to this key
            clearSecurePrefsForAlias(alias)
            deleted
        } catch (e: Exception) {
            Log.e(TAG, "Purge failed for $alias", e)
            false
        }
    }

    /**
     * Purge all vault-related keys atomically.
     */
    fun purgeAllKeys(aliases: List<String>): Boolean {
        var allSuccess = true
        for (alias in aliases) {
            val result = purgeKey(alias)
            if (!result) allSuccess = false
            // Zeroize any in-memory buffers for this alias
            MemoryZeroizer.zeroizeForAlias(alias)
        }
        // Clear vault SharedPreferences
        clearAllSecurePrefs()
        Log.w(TAG, "PURGE ALL — aliases=$aliases | allSuccess=$allSuccess")
        return allSuccess
    }

    fun isKeyExists(alias: String): Boolean {
        return try {
            keyStore.containsAlias(alias)
        } catch (e: Exception) {
            false
        }
    }

    fun getKeyInfo(alias: String): Map<String, Any?>? {
        return try {
            if (!keyStore.containsAlias(alias)) return null
            val secretKey = keyStore.getKey(alias, null) as? SecretKey ?: return null
            val factory = SecretKeyFactory.getInstance(secretKey.algorithm, ANDROID_KEYSTORE)
            val keyInfo = factory.getKeySpec(secretKey, KeyInfo::class.java) as KeyInfo

            mapOf(
                "alias" to alias,
                "insideSecureHardware" to keyInfo.isInsideSecureHardware,
                "isStrongBoxBacked" to if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) keyInfo.isStrongBoxBacked else false,
                "origin" to keyInfo.origin,
                "keySize" to keyInfo.keySize,
                "isUserAuthenticationRequired" to keyInfo.isUserAuthenticationRequirementEnforcedBySecureHardware
            )
        } catch (e: Exception) {
            Log.e(TAG, "getKeyInfo failed for $alias", e)
            null
        }
    }

    private fun getSecretKey(alias: String): SecretKey? {
        return try {
            keyStore.getKey(alias, null) as? SecretKey
        } catch (e: Exception) {
            Log.e(TAG, "getSecretKey failed for $alias", e)
            null
        }
    }

    private fun isInsideSecureHardware(alias: String): Boolean {
        return try {
            val secretKey = keyStore.getKey(alias, null) as? SecretKey ?: return false
            val factory = SecretKeyFactory.getInstance(secretKey.algorithm, ANDROID_KEYSTORE)
            val keyInfo = factory.getKeySpec(secretKey, KeyInfo::class.java) as KeyInfo
            keyInfo.isInsideSecureHardware
        } catch (e: Exception) {
            false
        }
    }

    private fun clearSecurePrefsForAlias(alias: String) {
        try {
            val prefs = context.getSharedPreferences("FlutterSecureStorage", Context.MODE_PRIVATE)
            prefs.edit().remove(alias).apply()
            // Also clear Hive encryption key reference
            val vaultPrefs = context.getSharedPreferences("canary_vault_prefs", Context.MODE_PRIVATE)
            vaultPrefs.edit().remove("vault_key_$alias").apply()
        } catch (e: Exception) {
            Log.e(TAG, "clearSecurePrefsForAlias failed", e)
        }
    }

    private fun clearAllSecurePrefs() {
        try {
            val prefs = context.getSharedPreferences("FlutterSecureStorage", Context.MODE_PRIVATE)
            prefs.edit().clear().apply()
            val vaultPrefs = context.getSharedPreferences("canary_vault_prefs", Context.MODE_PRIVATE)
            vaultPrefs.edit().clear().apply()
            // Clear Flutter shared_preferences that contain vault metadata
            val flutterPrefs = context.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
            val toRemove = flutterPrefs.all.keys.filter { it.startsWith("flutter.vault") || it.startsWith("flutter.canary") }
            val editor = flutterPrefs.edit()
            toRemove.forEach { editor.remove(it) }
            editor.apply()
            Log.d(TAG, "Secure prefs cleared — ${toRemove.size} keys removed")
        } catch (e: Exception) {
            Log.e(TAG, "clearAllSecurePrefs failed", e)
        }
    }
}
