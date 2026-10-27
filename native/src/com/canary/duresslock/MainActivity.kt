package com.canary.duresslock

import android.app.Activity
import android.graphics.Color
import android.os.Bundle
import android.view.View
import android.view.WindowManager
import android.widget.FrameLayout
import android.widget.Toast
import com.canary.duresslock.ui.DecoyScreen
import com.canary.duresslock.ui.DuressConfigDialog
import com.canary.duresslock.ui.LockScreen
import com.canary.duresslock.ui.SetupScreen
import com.canary.duresslock.ui.T
import com.canary.duresslock.ui.VaultScreen

/**
 * Canary Duress Lock — native Android host.
 *
 * State machine: setup → locked → vault → decoy.
 * The duress hand-off is a plain view swap: no dialog, no error, no delay.
 */
class MainActivity : Activity() {

    private lateinit var engine: DuressEngine
    private lateinit var root: FrameLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        engine = DuressEngine(this)
        root = FrameLayout(this)
        root.setBackgroundColor(T.OBSIDIAN)
        setContentView(root)

        // FLAG_SECURE would block screenshots of the vault. Left off so the flow is
        // testable on emulators; enable for production (see README → security notes).
        // window.setFlags(WindowManager.LayoutParams.FLAG_SECURE, WindowManager.LayoutParams.FLAG_SECURE)

        if (!engine.hasPinSetup()) showSetup() else showLock()
    }

    // ── Screens ──

    private fun showSetup() {
        applyBars(dark = true)
        swap(SetupScreen(this, engine) { showLock() })
    }

    private fun showLock() {
        applyBars(dark = true)
        swap(LockScreen(
            ctx = this,
            engine = engine,
            onMaster = { showVault() },
            onDuress = { showDecoy() },
            onConfig = { showConfig() },
            onToast = { msg -> toast(msg) }
        ))
    }

    private fun showVault() {
        applyBars(dark = true)
        swap(VaultScreen(this, engine, onLock = { showLock() }, onConfig = { showConfig() }))
    }

    private fun showDecoy() {
        applyBars(dark = false)
        swap(DecoyScreen(this) { showLock() })
    }

    private fun showConfig() {
        DuressConfigDialog(this, engine) {
            toast("Configuration saved")
            if (root.childCount > 0) {
                val current = root.getChildAt(0)
                if (current is VaultScreen) showVault()
                else if (current is LockScreen) showLock()
            }
        }.show()
    }

    // ── Plumbing ──

    private fun swap(view: View) {
        root.removeAllViews()
        root.addView(view, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT,
            FrameLayout.LayoutParams.MATCH_PARENT
        ))
        view.alpha = 0f
        view.animate().alpha(1f).setDuration(200).start()
    }

    private fun applyBars(dark: Boolean) {
        val bg = if (dark) T.OBSIDIAN else T.DECOY_BG
        window.statusBarColor = bg
        window.navigationBarColor = bg
        @Suppress("DEPRECATION")
        run {
            var flags = window.decorView.systemUiVisibility
            flags = if (dark) flags and View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR.inv()
            else flags or View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
            window.decorView.systemUiVisibility = flags
        }
    }

    private fun toast(message: String) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
    }

    @Deprecated("Back button semantics")
    override fun onBackPressed() {
        // Never expose the vault or a way out of the decoy through the back button.
        val current = if (root.childCount > 0) root.getChildAt(0) else null
        when (current) {
            is DecoyScreen -> Unit
            is VaultScreen -> showLock()
            else -> super.onBackPressed()
        }
    }
}
