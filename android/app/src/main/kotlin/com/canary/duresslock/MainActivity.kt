package com.canary.duresslock

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.os.Build
import android.os.Bundle
import android.util.Log
import androidx.biometric.BiometricManager
import com.canary.duresslock.security.CanaryDeviceAdminReceiver
import com.canary.duresslock.security.KeyStoreManager
import com.canary.duresslock.security.MemoryZeroizer
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * MainActivity — Flutter entry point with native security channel bridges.
 *
 * Exposes three MethodChannels to Dart:
 *   1. com.canary.duresslock/keystore      — KeyStore operations
 *   2. com.canary.duresslock/device_admin  — Device Admin / wipe
 *   3. com.canary.duresslock/zeroizer      — Memory zeroization
 */
class MainActivity : FlutterActivity() {

    companion object {
        private const val TAG = "CanaryMainActivity"
        private const val CHANNEL_KEYSTORE = "com.canary.duresslock/keystore"
        private const val CHANNEL_DEVICE_ADMIN = "com.canary.duresslock/device_admin"
        private const val CHANNEL_ZEROIZER = "com.canary.duresslock/zeroizer"
    }

    private lateinit var keyStoreManager: KeyStoreManager

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        keyStoreManager = KeyStoreManager(this)

        setupKeyStoreChannel(flutterEngine)
        setupDeviceAdminChannel(flutterEngine)
        setupZeroizerChannel(flutterEngine)

        Log.i(TAG, "Canary Duress Lock — all channels configured | StrongBox=${hasStrongBox()}")
    }

    private fun setupKeyStoreChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_KEYSTORE)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "generateMasterKey" -> {
                        val alias = call.argument<String>("alias") ?: "canary_master_vault_key_v1"
                        val requireBiometric = call.argument<Boolean>("requireBiometric") ?: false
                        val useStrongBox = call.argument<Boolean>("useStrongBox") ?: true
                        val success = keyStoreManager.generateMasterKey(alias, requireBiometric, useStrongBox)
                        result.success(success)
                    }
                    "encrypt" -> {
                        val alias = call.argument<String>("alias") ?: ""
                        val plaintext = call.argument<String>("plaintext") ?: ""
                        val encrypted = keyStoreManager.encrypt(alias, plaintext)
                        if (encrypted != null) result.success(encrypted)
                        else result.error("ENCRYPT_FAILED", "Encryption failed for $alias", null)
                    }
                    "decrypt" -> {
                        val alias = call.argument<String>("alias") ?: ""
                        val ciphertext = call.argument<String>("ciphertext") ?: ""
                        val decrypted = keyStoreManager.decrypt(alias, ciphertext)
                        if (decrypted != null) result.success(decrypted)
                        else result.error("DECRYPT_FAILED", "Decryption failed for $alias", null)
                    }
                    "purgeAllKeys" -> {
                        @Suppress("UNCHECKED_CAST")
                        val aliases = call.argument<List<String>>("aliases") ?: emptyList()
                        val success = keyStoreManager.purgeAllKeys(aliases)
                        result.success(success)
                    }
                    "isKeyExists" -> {
                        val alias = call.argument<String>("alias") ?: ""
                        result.success(keyStoreManager.isKeyExists(alias))
                    }
                    "getKeyInfo" -> {
                        val alias = call.argument<String>("alias") ?: ""
                        val info = keyStoreManager.getKeyInfo(alias)
                        result.success(info)
                    }
                    "clearSecureStorage" -> {
                        try {
                            getSharedPreferences("FlutterSecureStorage", Context.MODE_PRIVATE).edit().clear().apply()
                            getSharedPreferences("canary_vault_prefs", Context.MODE_PRIVATE).edit().clear().apply()
                            result.success(true)
                        } catch (e: Exception) {
                            result.error("CLEAR_FAILED", e.message, null)
                        }
                    }
                    "isBiometricAvailable" -> {
                        val biometricManager = BiometricManager.from(this)
                        val canAuth = biometricManager.canAuthenticate(BiometricManager.Authenticators.BIOMETRIC_STRONG)
                        result.success(canAuth == BiometricManager.BIOMETRIC_SUCCESS)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun setupDeviceAdminChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_DEVICE_ADMIN)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "isAdminActive" -> {
                        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                        val component = ComponentName(this, CanaryDeviceAdminReceiver::class.java)
                        result.success(dpm.isAdminActive(component))
                    }
                    "requestAdmin" -> {
                        val intent = Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                            putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN, ComponentName(this@MainActivity, CanaryDeviceAdminReceiver::class.java))
                            putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION, "Enable Canary Duress Lock to allow emergency device wipe when duress PIN is entered under coercion.")
                        }
                        startActivity(intent)
                        result.success(true)
                    }
                    "wipeDevice" -> {
                        val dpm = getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
                        val component = ComponentName(this, CanaryDeviceAdminReceiver::class.java)
                        if (!dpm.isAdminActive(component)) {
                            result.error("ADMIN_NOT_ACTIVE", "Device Admin not active — user must enable in Settings", null)
                            return@setMethodCallHandler
                        }
                        try {
                            dpm.wipeData(0)
                            result.success(true)
                        } catch (e: SecurityException) {
                            result.error("WIPE_DENIED", e.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun setupZeroizerChannel(engine: FlutterEngine) {
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_ZEROIZER)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "zeroizeAll" -> {
                        val success = MemoryZeroizer.zeroizeAll()
                        result.success(success)
                    }
                    "zeroizeBuffer" -> {
                        val bufferId = call.argument<String>("bufferId") ?: ""
                        val success = MemoryZeroizer.zeroizeBuffer(bufferId)
                        result.success(success)
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun hasStrongBox(): Boolean {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            packageManager.hasSystemFeature("android.hardware.strongbox_keystore")
        } else {
            false
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Prevent screenshots in vault mode — FLAG_SECURE
        // Note: Commented for emulator testing; uncomment for production
        // window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)
        Log.i(TAG, "Canary Duress Lock initialized — StrongBox available: ${hasStrongBox()}")
    }
}
