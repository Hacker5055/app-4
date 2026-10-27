package com.canary.duresslock.security

import android.app.admin.DeviceAdminReceiver
import android.content.Context
import android.content.Intent
import android.util.Log
import android.widget.Toast

/**
 * CanaryDeviceAdminReceiver — Device Administrator for optional hard wipe.
 *
 * Must be declared in AndroidManifest with BIND_DEVICE_ADMIN permission.
 * User must explicitly activate via system Settings > Security > Device Admin.
 *
 * When duress action is set to HARD_WIPE, this receiver authorizes
 * DevicePolicyManager.wipeData(0) to factory-reset the device.
 */
class CanaryDeviceAdminReceiver : DeviceAdminReceiver() {

    companion object {
        private const val TAG = "CanaryDeviceAdmin"
    }

    override fun onEnabled(context: Context, intent: Intent) {
        super.onEnabled(context, intent)
        Log.i(TAG, "Device Admin ENABLED — hard wipe capability armed")
        Toast.makeText(context, "Canary Duress Lock — Device Admin enabled", Toast.LENGTH_SHORT).show()
    }

    override fun onDisabled(context: Context, intent: Intent) {
        super.onDisabled(context, intent)
        Log.w(TAG, "Device Admin DISABLED — hard wipe no longer available")
        Toast.makeText(context, "Canary — Device Admin disabled", Toast.LENGTH_SHORT).show()
    }

    override fun onDisableRequested(context: Context, intent: Intent): CharSequence {
        Log.w(TAG, "Device Admin disable requested — warning user")
        return "Warning: Disabling Device Admin will prevent emergency wipe protection. Are you sure?"
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        Log.d(TAG, "DeviceAdmin onReceive: ${intent.action}")
    }
}
