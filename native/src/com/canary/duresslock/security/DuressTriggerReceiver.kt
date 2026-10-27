package com.canary.duresslock.security

import android.app.admin.DevicePolicyManager
import android.content.BroadcastReceiver
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.util.Log

/**
 * DuressTriggerReceiver — System-level duress event dispatcher.
 *
 * Listens for duress intents from the Flutter layer and orchestrates
 * the full purge sequence: KeyStore deletion, memory zeroization,
 * and optional device wipe.
 *
 * Also handles accessibility-service-triggered duress (optional keypad monitor).
 */
class DuressTriggerReceiver : BroadcastReceiver() {

    companion object {
        const val ACTION_DURESS_TRIGGER = "com.canary.duresslock.ACTION_DURESS_TRIGGER"
        const val ACTION_DURESS_PURGE_COMPLETE = "com.canary.duresslock.ACTION_DURESS_PURGE_COMPLETE"
        const val EXTRA_DURESS_ACTION = "duress_action"
        const val EXTRA_IS_MOCK = "is_mock"
        const val TAG = "DuressTrigger"

        const val ACTION_DECOY_ONLY = 1
        const val ACTION_DECOY_PURGE = 2
        const val ACTION_HARD_WIPE = 3
    }

    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != ACTION_DURESS_TRIGGER) return

        val action = intent.getIntExtra(EXTRA_DURESS_ACTION, ACTION_DECOY_PURGE)
        val isMock = intent.getBooleanExtra(EXTRA_IS_MOCK, false)

        Log.w(TAG, "DURESS RECEIVED — action=$action | mock=$isMock")

        if (isMock) {
            Log.w(TAG, "[MOCK] Duress would execute — simulating purge for verification")
            // In mock mode, just log and broadcast completion without actually wiping
            broadcastPurgeComplete(context, success = true, isMock = true)
            return
        }

        executeDuressSequence(context, action)
    }

    private fun executeDuressSequence(context: Context, action: Int) {
        try {
            val keyStoreManager = KeyStoreManager(context)

            when (action) {
                ACTION_DECOY_ONLY -> {
                    Log.i(TAG, "Decoy Only — no purge, launching decoy environment")
                    // No key deletion — just signal decoy launch
                    broadcastPurgeComplete(context, success = true, isMock = false)
                }

                ACTION_DECOY_PURGE -> {
                    Log.w(TAG, "Decoy + Purge — deleting KeyStore entries")
                    val aliases = listOf(
                        "canary_master_vault_key_v1",
                        "canary_biometric_key_v1"
                    )
                    val purgeSuccess = keyStoreManager.purgeAllKeys(aliases)
                    Log.w(TAG, "Purge result: $purgeSuccess")

                    // Zeroize memory buffers
                    val zeroSuccess = MemoryZeroizer.zeroizeAll()
                    Log.w(TAG, "Zeroization result: $zeroSuccess")

                    broadcastPurgeComplete(context, success = purgeSuccess && zeroSuccess, isMock = false)
                }

                ACTION_HARD_WIPE -> {
                    Log.w(TAG, "HARD WIPE — purging keys then wiping device")
                    val aliases = listOf(
                        "canary_master_vault_key_v1",
                        "canary_biometric_key_v1"
                    )
                    keyStoreManager.purgeAllKeys(aliases)
                    MemoryZeroizer.zeroizeAll()

                    // Attempt device wipe via DevicePolicyManager
                    val wipeSuccess = triggerDeviceWipe(context)
                    Log.w(TAG, "Device wipe result: $wipeSuccess")

                    broadcastPurgeComplete(context, success = wipeSuccess, isMock = false)
                }

                else -> {
                    Log.e(TAG, "Unknown duress action: $action")
                    broadcastPurgeComplete(context, success = false, isMock = false)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Duress sequence failed", e)
            broadcastPurgeComplete(context, success = false, isMock = false)
        }
    }

    private fun triggerDeviceWipe(context: Context): Boolean {
        return try {
            val dpm = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as DevicePolicyManager
            val adminComponent = ComponentName(context, CanaryDeviceAdminReceiver::class.java)

            if (!dpm.isAdminActive(adminComponent)) {
                Log.e(TAG, "Device Admin not active — cannot wipe. User must enable in settings.")
                return false
            }

            // wipeData(0) — factory reset without external storage wipe flag
            // WIPE_EXTERNAL_STORAGE flag (1) would also wipe SD card
            Log.w(TAG, "Invoking DevicePolicyManager.wipeData(0) — FACTORY RESET IMMINENT")
            dpm.wipeData(0)
            true
        } catch (e: SecurityException) {
            Log.e(TAG, "SecurityException during wipe — admin not active or permission denied", e)
            false
        } catch (e: Exception) {
            Log.e(TAG, "Device wipe failed", e)
            false
        }
    }

    private fun broadcastPurgeComplete(context: Context, success: Boolean, isMock: Boolean) {
        val intent = Intent(ACTION_DURESS_PURGE_COMPLETE).apply {
            putExtra("success", success)
            putExtra("is_mock", isMock)
            setPackage(context.packageName)
        }
        context.sendBroadcast(intent)
        Log.d(TAG, "Purge complete broadcast sent — success=$success | mock=$isMock")
    }
}
