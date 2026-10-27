package com.canary.duresslock

import android.content.Context
import com.canary.duresslock.security.KeyStoreManager
import com.canary.duresslock.security.MemoryZeroizer
import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

enum class AuthResult { MASTER, DURESS, INVALID }

/** Result of a duress sequence, with a step-by-step audit trail for the UI. */
class DuressReport {
    val entries = mutableListOf<String>()
    var success: Boolean = true

    private val fmt = SimpleDateFormat("HH:mm:ss", Locale.US)

    fun add(line: String) {
        entries.add("[${fmt.format(Date())}] $line")
    }

    fun text(): String = entries.joinToString("\n")
}

/**
 * Dual-PIN engine. Mirrors lib/core/services/duress_service.dart:
 * the duress hash is checked *before* the master hash so the two can never collide,
 * and every failed attempt is counted towards the lockout policy.
 */
class DuressEngine(private val ctx: Context) {

    companion object {
        const val ALIAS_MASTER = "canary_master_vault_key_v1"
        const val ALIAS_BIOMETRIC = "canary_biometric_key_v1"

        const val PIN_LENGTH = 6
        const val MAX_ATTEMPTS = 5
        const val LOCKOUT_SECONDS = 60

        const val ACTION_DECOY_ONLY = 1
        const val ACTION_DECOY_PURGE = 2
        const val ACTION_HARD_WIPE = 3

        private const val PEPPER = "CanaryDuressLock_v1_pepper_Sphinx_2024"

        fun actionLabel(action: Int): String = when (action) {
            ACTION_DECOY_ONLY -> "Decoy only — keep data intact"
            ACTION_DECOY_PURGE -> "Decoy + purge keys"
            ACTION_HARD_WIPE -> "Hard wipe via Device Admin"
            else -> "Unknown"
        }

        fun hashPin(pin: String): String {
            val digest = MessageDigest.getInstance("SHA-256")
            val bytes = digest.digest("$PEPPER::$pin".toByteArray(Charsets.UTF_8))
            return bytes.joinToString("") { "%02x".format(it) }
        }
    }

    private val prefs = ctx.getSharedPreferences("canary_prefs", Context.MODE_PRIVATE)
    private val keyStore by lazy { KeyStoreManager(ctx) }

    // ── Provisioning ──

    fun hasPinSetup(): Boolean = prefs.contains("master_hash")

    fun setMasterPin(pin: String) {
        prefs.edit().putString("master_hash", hashPin(pin)).apply()
        try {
            keyStore.generateMasterKey(ALIAS_MASTER, requireBiometric = false, useStrongBox = true)
        } catch (e: Exception) {
            android.util.Log.w("DuressEngine", "Key generation failed: ${e.message}")
        }
    }

    fun setDuressPin(pin: String) {
        prefs.edit().putString("duress_hash", hashPin(pin)).apply()
    }

    fun setDuressAction(action: Int) {
        prefs.edit().putInt("duress_action", action).apply()
    }

    fun duressAction(): Int = prefs.getInt("duress_action", ACTION_DECOY_PURGE)

    // ── Mock testing ──

    fun isMockMode(): Boolean = prefs.getBoolean("mock_mode", true)

    fun setMockMode(enabled: Boolean) {
        prefs.edit().putBoolean("mock_mode", enabled).apply()
    }

    // ── Lockout ──

    fun failedAttempts(): Int = prefs.getInt("failed_attempts", 0)

    fun lockedForSeconds(): Int {
        val until = prefs.getLong("lock_until", 0L)
        val left = until - System.currentTimeMillis()
        return if (left > 0) (left / 1000).toInt() + 1 else 0
    }

    fun resetAttempts() {
        prefs.edit().putInt("failed_attempts", 0).remove("lock_until").apply()
    }

    // ── Verification ──

    fun verify(pin: String): AuthResult {
        if (lockedForSeconds() > 0) return AuthResult.INVALID
        val input = hashPin(pin)
        val duress = prefs.getString("duress_hash", null)
        val master = prefs.getString("master_hash", null)

        // Duress takes precedence — no visual or timing difference.
        if (duress != null && input == duress) {
            resetAttempts()
            return AuthResult.DURESS
        }
        if (master != null && input == master) {
            resetAttempts()
            return AuthResult.MASTER
        }

        val next = failedAttempts() + 1
        val editor = prefs.edit().putInt("failed_attempts", next)
        if (next >= MAX_ATTEMPTS) {
            editor.putLong("lock_until", System.currentTimeMillis() + LOCKOUT_SECONDS * 1000L)
        }
        editor.apply()
        return AuthResult.INVALID
    }

    // ── Duress execution ──

    fun executeDuress(): DuressReport {
        val report = DuressReport()
        val action = duressAction()
        val mock = isMockMode()

        report.add("DURESS PIN matched — action: ${actionLabel(action)}")
        report.add("Mock testing mode: $mock")

        if (mock) {
            report.add("[MOCK] KeyStore.deleteEntry($ALIAS_MASTER)")
            report.add("[MOCK] key material would be destroyed in StrongBox/TEE")
            report.add("[MOCK] MemoryZeroizer.zeroizeAll() → Arrays.fill(0x00) ×3")
            report.add("[MOCK] secure preferences + vault key table cleared")
            if (action == ACTION_HARD_WIPE) {
                report.add("[MOCK] DevicePolicyManager.wipeData(0) — BLOCKED by mock mode")
            }
            report.add("MOCK SEQUENCE COMPLETE — nothing was deleted")
            report.success = true
            incrementDuressCount()
            return report
        }

        // ── Real purge ──
        try {
            val purged = keyStore.purgeAllKeys(listOf(ALIAS_MASTER, ALIAS_BIOMETRIC))
            report.add(
                if (purged) "KeyStore PURGED — key deleted from secure hardware"
                else "KeyStore purge reported incomplete"
            )
            report.success = purged

            val zeroed = MemoryZeroizer.zeroizeAll()
            report.add(if (zeroed) "Memory ZEROIZED — buffers overwritten" else "Memory zeroization incomplete")

            prefs.edit().clear().apply()
            report.add("Vault preferences cleared")

            if (action == ACTION_HARD_WIPE) {
                val wiped = triggerWipe()
                report.add(
                    if (wiped) "WIPE COMMAND SENT — device will factory reset"
                    else "Wipe refused — Device Admin is not active"
                )
            }
            report.add("DURESS SEQUENCE COMPLETE")
        } catch (e: Exception) {
            report.success = false
            report.add("ERROR during duress sequence: ${e.message}")
        }

        incrementDuressCount()
        return report
    }

    private fun triggerWipe(): Boolean = try {
        val dpm = ctx.getSystemService(Context.DEVICE_POLICY_SERVICE)
            as android.app.admin.DevicePolicyManager
        val admin = android.content.ComponentName(
            ctx, com.canary.duresslock.security.CanaryDeviceAdminReceiver::class.java
        )
        if (!dpm.isAdminActive(admin)) {
            false
        } else {
            dpm.wipeData(0)
            true
        }
    } catch (e: Exception) {
        false
    }

    private fun incrementDuressCount() {
        val count = prefs.getInt("duress_count", 0) + 1
        prefs.edit().putInt("duress_count", count).apply()
    }

    fun duressCount(): Int = prefs.getInt("duress_count", 0)

    fun isDeviceAdminActive(): Boolean = try {
        val dpm = ctx.getSystemService(Context.DEVICE_POLICY_SERVICE)
            as android.app.admin.DevicePolicyManager
        dpm.isAdminActive(
            android.content.ComponentName(
                ctx, com.canary.duresslock.security.CanaryDeviceAdminReceiver::class.java
            )
        )
    } catch (e: Exception) {
        false
    }

    fun keyInfo(): Map<String, Any?>? = try {
        keyStore.getKeyInfo(ALIAS_MASTER)
    } catch (e: Exception) {
        null
    }
}
