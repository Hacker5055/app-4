package com.canary.duresslock.security

import android.accessibilityservice.AccessibilityService
import android.content.Intent
import android.util.Log
import android.view.accessibility.AccessibilityEvent

/**
 * AccessibilityMonitorService — Optional lockscreen/keypad input monitor.
 *
 * When enabled by the user (Settings > Accessibility), this service can
 * detect duress PIN entry at the system level — even outside the app.
 *
 * NOTE: This service is OPTIONAL and disabled by default.
 * It requires explicit user consent via system accessibility settings.
 * The permission is declared but not auto-enabled.
 *
 * Currently monitors for duress trigger intents; future versions may
 * integrate keypad pattern detection for hardware key combinations.
 */
class AccessibilityMonitorService : AccessibilityService() {

    companion object {
        private const val TAG = "CanaryAccessibility"
        var isServiceConnected = false
            private set
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        isServiceConnected = true
        Log.i(TAG, "Accessibility service connected — monitoring enabled")

        // Configure monitoring dynamically
        // serviceInfo is set via accessibility_service.xml
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (event == null) return

        // Only process window state changes and view focus events
        // This is intentionally minimal to preserve battery and privacy
        when (event.eventType) {
            AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED -> {
                val packageName = event.packageName?.toString() ?: return
                // Monitor for lockscreen or PIN entry screens if needed
                // Currently passive — duress is app-triggered via PIN verification
                Log.d(TAG, "Window changed: $packageName")
            }
            AccessibilityEvent.TYPE_VIEW_TEXT_CHANGED -> {
                // Future: detect duress pattern in system PIN entry
                // Not implemented — requires careful privacy handling
            }
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "Accessibility service interrupted")
    }

    override fun onDestroy() {
        super.onDestroy()
        isServiceConnected = false
        Log.i(TAG, "Accessibility service destroyed")
    }

    override fun onUnbind(intent: Intent?): Boolean {
        isServiceConnected = false
        Log.i(TAG, "Accessibility service unbound")
        return super.onUnbind(intent)
    }
}
