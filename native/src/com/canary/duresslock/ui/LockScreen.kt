package com.canary.duresslock.ui

import android.app.AlertDialog
import android.content.Context
import android.view.Gravity
import android.view.View
import android.widget.LinearLayout
import android.widget.ScrollView
import com.canary.duresslock.AuthResult
import com.canary.duresslock.DuressEngine
import com.canary.duresslock.DuressReport

/**
 * Lock gate. Renders identically for both PIN types — the duress path is silent,
 * with the same "Verifying…" state and no error, count or timing difference.
 */
class LockScreen(
    ctx: Context,
    private val engine: DuressEngine,
    private val onMaster: () -> Unit,
    private val onDuress: () -> Unit,
    private val onConfig: () -> Unit,
    private val onToast: (String) -> Unit
) : ScrollView(ctx) {

    private val pad: PinPad
    private var busy = false
    private var countdownHandle: Runnable? = null

    init {
        isFillViewport = true
        setBackgroundColor(T.OBSIDIAN)

        val col = vcol(ctx)
        col.gravity = Gravity.CENTER_HORIZONTAL
        col.setPadding(ctx.dpi(18f), ctx.dpi(10f), ctx.dpi(18f), ctx.dpi(16f))
        addView(col, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT))

        // ── mock mode banner ──
        if (engine.isMockMode()) {
            val banner = hrow(ctx)
            banner.background = rounded(ctx, T.alpha(T.AMBER, 0.11f), 9f, T.alpha(T.AMBER, 0.3f))
            banner.setPadding(ctx.dpi(12f), ctx.dpi(8f), ctx.dpi(12f), ctx.dpi(8f))
            banner.addView(text(ctx, "●", 8f, T.AMBER, bold = true))
            banner.addView(hspacer(ctx, 8f))
            banner.addView(text(ctx, "MOCK TESTING MODE — NO REAL DATA LOSS", 9f, T.AMBER, bold = true, letterSpacing = 0.04f))
            banner.addView(hspacer(ctx, 10f))
            banner.addView(text(ctx, "CONFIG", 8.5f, T.AMBER, bold = true, letterSpacing = 0.1f).apply {
                setOnClickListener { onConfig() }
            })
            banner.setOnClickListener { onConfig() }
            banner.layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = ctx.dpi(14f) }
            col.addView(banner)
        }

        col.addView(ShieldView(ctx), LinearLayout.LayoutParams(ctx.dpi(84f), ctx.dpi(84f)).apply {
            topMargin = ctx.dpi(10f)
        })

        col.addView(text(ctx, "CANARY", 21f, T.TEXT, bold = true, letterSpacing = 0.17f).apply {
            setPadding(0, ctx.dpi(14f), 0, 0)
        })
        col.addView(text(ctx, "DURESS LOCK", 10f, T.GREEN, bold = true, letterSpacing = 0.3f).apply {
            setPadding(0, ctx.dpi(3f), 0, 0)
        })

        val chipRow = hrow(ctx)
        chipRow.background = rounded(ctx, T.PANEL, 20f, T.BORDER)
        chipRow.setPadding(ctx.dpi(12f), ctx.dpi(5f), ctx.dpi(12f), ctx.dpi(5f))
        chipRow.addView(View(ctx).apply {
            background = circle(T.GREEN)
            layoutParams = LinearLayout.LayoutParams(ctx.dpi(6f), ctx.dpi(6f))
        })
        chipRow.addView(hspacer(ctx, 7f))
        chipRow.addView(text(ctx, "SECURE VAULT LOCKED", 9f, T.TEXT2, bold = true, letterSpacing = 0.1f))
        chipRow.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = ctx.dpi(12f) }
        col.addView(chipRow)

        // ── PIN pad ──
        pad = PinPad(ctx) { onPinComplete(it) }
        col.addView(pad)

        col.addView(text(ctx, "PROTECTED BY HARDWARE KEYSTORE", 8f, T.GHOST, letterSpacing = 0.12f).apply {
            setPadding(0, ctx.dpi(18f), 0, 0)
            gravity = Gravity.CENTER
        })
        col.addView(text(ctx, "StrongBox · TEE isolated · AES-256-GCM", 8f, T.alpha(T.GHOST, 0.8f)).apply {
            setPadding(0, ctx.dpi(3f), 0, 0)
            gravity = Gravity.CENTER
        })
    }

    private fun onPinComplete(value: String) {
        if (busy) return
        busy = true
        // Capture mock state before a real purge clears preferences.
        val mock = engine.isMockMode()
        pad.showInfo("Verifying…")

        postDelayed({
            when (engine.verify(value)) {
                AuthResult.MASTER -> {
                    busy = false
                    pad.reset()
                    onMaster()
                }

                AuthResult.DURESS -> {
                    val report = engine.executeDuress()
                    busy = false
                    pad.reset()
                    if (mock) showMockLog(report) else onDuress()
                }

                AuthResult.INVALID -> {
                    busy = false
                    pad.reset()
                    val attempts = engine.failedAttempts()
                    val lockLeft = engine.lockedForSeconds()
                    if (lockLeft > 0) {
                        startLockout(lockLeft)
                    } else {
                        val left = DuressEngine.MAX_ATTEMPTS - attempts
                        pad.showError("Incorrect PIN — $left attempts remaining")
                    }
                }
            }
        }, 380)
    }

    private fun startLockout(seconds: Int) {
        pad.setInputEnabled(false)
        var left = seconds
        countdownHandle?.let { removeCallbacks(it) }
        val tick = object : Runnable {
            override fun run() {
                if (left <= 0) {
                    pad.setInputEnabled(true)
                    pad.reset()
                    return
                }
                pad.showError("Locked out — retry in ${left}s")
                left--
                postDelayed(this, 1000)
            }
        }
        countdownHandle = tick
        post(tick)
    }

    private fun showMockLog(report: DuressReport) {
        val ctx = context
        AlertDialog.Builder(ctx)
            .setTitle("MOCK duress log")
            .setMessage(report.text() + "\n\nNo data was deleted — mock mode is on.")
            .setCancelable(false)
            .setPositiveButton("Enter decoy mode") { _, _ -> onDuress() }
            .show()
        onToast("Mock purge simulated")
    }

    override fun onDetachedFromWindow() {
        countdownHandle?.let { removeCallbacks(it) }
        super.onDetachedFromWindow()
    }
}
