package com.canary.duresslock.ui

import android.content.Context
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.ScrollView
import com.canary.duresslock.DuressEngine

/**
 * First-launch provisioning: master PIN → duress PIN → response action.
 * The duress PIN is rejected if it matches the master PIN.
 */
class SetupScreen(
    ctx: Context,
    private val engine: DuressEngine,
    private val onDone: () -> Unit
) : ScrollView(ctx) {

    private val container = vcol(ctx)
    private var step = 0
    private var masterPin: String? = null
    private var duressPin: String? = null
    private var action = DuressEngine.ACTION_DECOY_PURGE

    private val titles = arrayOf(
        "Set Master PIN" to "Unlocks your encrypted vault",
        "Set Duress PIN" to "Silently triggers purge + decoy",
        "Choose duress response" to "What happens under coercion"
    )

    init {
        isFillViewport = true
        setBackgroundColor(T.OBSIDIAN)
        container.gravity = Gravity.CENTER_HORIZONTAL
        container.setPadding(ctx.dpi(18f), ctx.dpi(24f), ctx.dpi(18f), ctx.dpi(24f))
        addView(container, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT))
        renderStep()
    }

    private fun renderStep() {
        container.removeAllViews()
        val ctx = context

        container.addView(ShieldView(ctx), LinearLayout.LayoutParams(ctx.dpi(64f), ctx.dpi(64f)))
        container.addView(text(ctx, "CANARY DURESS LOCK", 13f, T.TEXT, bold = true, letterSpacing = 0.14f).apply {
            setPadding(0, ctx.dpi(12f), 0, 0)
        })
        container.addView(text(ctx, "FIRST-LAUNCH PROVISIONING", 8.5f, T.GREEN, bold = true, letterSpacing = 0.18f).apply {
            setPadding(0, ctx.dpi(4f), 0, ctx.dpi(18f))
        })

        val card = hrow(ctx)
        card.background = rounded(ctx, T.alpha(T.GREEN, 0.08f), 12f, T.alpha(T.GREEN, 0.22f))
        card.setPadding(ctx.dpi(12f), ctx.dpi(11f), ctx.dpi(12f), ctx.dpi(11f))
        val badge = text(ctx, "${step + 1}", 11f, T.GREEN, bold = true)
        badge.gravity = Gravity.CENTER
        badge.background = rounded(ctx, T.alpha(T.GREEN, 0.16f), 8f)
        badge.layoutParams = LinearLayout.LayoutParams(ctx.dpi(30f), ctx.dpi(30f))
        card.addView(badge)
        card.addView(hspacer(ctx, 11f))
        val meta = vcol(ctx)
        meta.addView(text(ctx, titles[step].first, 12f, T.TEXT, bold = true))
        meta.addView(text(ctx, titles[step].second, 10f, T.MUTED).apply { setPadding(0, ctx.dpi(1f), 0, 0) })
        card.addView(meta)
        card.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
        )
        container.addView(card)

        if (step < 2) {
            val pad = PinPad(ctx) { onPin(it) }
            container.addView(pad)
        } else {
            renderActionPicker()
        }
    }

    private fun renderActionPicker() {
        val ctx = context
        val options = listOf(
            Triple(DuressEngine.ACTION_DECOY_ONLY, "Decoy only", "Show the fake environment, keep data intact"),
            Triple(DuressEngine.ACTION_DECOY_PURGE, "Decoy + purge keys", "Delete KeyStore keys, then show the decoy"),
            Triple(DuressEngine.ACTION_HARD_WIPE, "Hard wipe device", "Factory reset via Device Admin")
        )

        for ((value, title, desc) in options) {
            val selected = action == value
            val accent = if (value == DuressEngine.ACTION_HARD_WIPE) T.RED else T.GREEN
            val row = hrow(ctx)
            row.background = rounded(
                ctx,
                if (selected) T.alpha(accent, 0.09f) else T.PANEL,
                12f,
                if (selected) accent else T.BORDER,
                if (selected) 1.5f else 1f
            )
            row.setPadding(ctx.dpi(13f), ctx.dpi(12f), ctx.dpi(13f), ctx.dpi(12f))
            val dot = android.view.View(ctx)
            dot.background = circle(if (selected) accent else T.alpha(T.GHOST, 0.6f))
            dot.layoutParams = LinearLayout.LayoutParams(ctx.dpi(9f), ctx.dpi(9f))
            row.addView(dot)
            row.addView(hspacer(ctx, 11f))
            val box = vcol(ctx)
            box.addView(text(ctx, title, 12f, if (selected) T.TEXT else T.TEXT2, bold = true))
            box.addView(text(ctx, desc, 10f, T.MUTED).apply { setPadding(0, ctx.dpi(2f), 0, 0) })
            row.addView(box, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
            row.layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = ctx.dpi(9f) }
            row.setOnClickListener {
                action = value
                renderStep()
            }
            container.addView(row)
        }

        container.addView(actionButton(ctx, "Initialize secure vault", T.GREEN) {
            finish()
        }.apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { topMargin = ctx.dpi(18f) }
        })
    }

    private fun onPin(value: String) {
        if (step == 0) {
            masterPin = value
            step = 1
            renderStep()
        } else if (step == 1) {
            if (value == masterPin) {
                val ctx = context
                renderStep()
                // re-render cleared the pad; show the error on the fresh one
                val pad = container.getChildAt(container.childCount - 1)
                if (pad is PinPad) pad.showError("Duress PIN must differ from Master PIN")
                return
            }
            duressPin = value
            step = 2
            renderStep()
        }
    }

    private fun finish() {
        val m = masterPin ?: return
        val d = duressPin ?: return
        engine.setMasterPin(m)
        engine.setDuressPin(d)
        engine.setDuressAction(action)
        onDone()
    }
}
