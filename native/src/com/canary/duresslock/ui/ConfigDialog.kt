package com.canary.duresslock.ui

import android.app.Dialog
import android.content.Context
import android.content.Intent
import android.app.admin.DevicePolicyManager
import android.os.Bundle
import android.view.Gravity
import android.view.ViewGroup
import android.widget.FrameLayout
import android.view.Window
import android.widget.LinearLayout
import android.widget.ScrollView
import com.canary.duresslock.DuressEngine
import com.canary.duresslock.security.CanaryDeviceAdminReceiver

/**
 * Duress configuration sheet: response action, mock testing, device admin.
 */
class DuressConfigDialog(
    private val ctx: Context,
    private val engine: DuressEngine,
    private val onSaved: () -> Unit
) : Dialog(ctx) {

    private var action = engine.duressAction()
    private var mock = engine.isMockMode()
    private var admin = engine.isDeviceAdminActive()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        requestWindowFeature(Window.FEATURE_NO_TITLE)
        setContentView(buildContent())
        setCanceledOnTouchOutside(true)
        window?.let { w ->
            w.setBackgroundDrawable(rounded(ctx, T.PANEL, 22f, T.BORDER))
            w.setLayout(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            )
            w.setGravity(Gravity.BOTTOM)
            w.setDimAmount(0.7f)
            w.addFlags(android.view.WindowManager.LayoutParams.FLAG_DIM_BEHIND)
        }
    }

    private fun buildContent(): LinearLayout {
        val root = vcol(ctx)
        root.setBackgroundColor(T.PANEL)
        root.setPadding(ctx.dpi(20f), ctx.dpi(14f), ctx.dpi(20f), ctx.dpi(20f))

        val grabber = android.view.View(ctx).apply {
            setBackgroundColor(T.BORDER)
            layoutParams = LinearLayout.LayoutParams(ctx.dpi(38f), ctx.dpi(4f)).apply {
                gravity = Gravity.CENTER_HORIZONTAL
                bottomMargin = ctx.dpi(16f)
            }
        }
        root.addView(grabber)

        val head = hrow(ctx)
        head.addView(text(ctx, "⛨", 15f, T.GREEN).apply {
            gravity = Gravity.CENTER
            background = rounded(ctx, T.alpha(T.GREEN, 0.12f), 11f)
            layoutParams = LinearLayout.LayoutParams(ctx.dpi(38f), ctx.dpi(38f))
        })
        head.addView(hspacer(ctx, 11f))
        val titles = vcol(ctx)
        titles.addView(text(ctx, "Duress configuration", 15f, T.TEXT, bold = true))
        titles.addView(text(ctx, "Emergency response actions", 10f, T.MUTED))
        head.addView(titles, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        root.addView(head)

        val scroll = ScrollView(ctx)
        scroll.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, ctx.dpi(330f)
        ).apply { topMargin = ctx.dpi(14f) }
        val body = vcol(ctx)
        scroll.addView(body, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT
        ))
        root.addView(scroll)

        body.addView(sectionLabel(ctx, "Duress response action"))

        val options = listOf(
            Triple(DuressEngine.ACTION_DECOY_ONLY, "Decoy only", "Show the fake environment, keep vault data intact"),
            Triple(DuressEngine.ACTION_DECOY_PURGE, "Decoy + purge keys", "Delete KeyStore keys, then show the decoy"),
            Triple(DuressEngine.ACTION_HARD_WIPE, "Hard wipe device", "Factory reset via Device Admin")
        )
        for ((value, title, desc) in options) {
            val selected = action == value
            val accent = if (value == DuressEngine.ACTION_HARD_WIPE) T.RED else T.GREEN
            body.addView(optionRow(value, title, desc, selected, accent))
        }

        body.addView(sectionLabel(ctx, "Security options"))
        body.addView(toggleRow(ctx, "Mock testing mode",
            if (mock) "ON — purges simulated, nothing deleted" else "OFF — real purge executes",
            mock, T.AMBER) { checked ->
            mock = checked
            engine.setMockMode(checked)
            rebuild()
        })
        body.addView(spacer(ctx, 9f))
        body.addView(toggleRow(ctx, "Device admin (hard wipe)",
            if (admin) "Active — wipe authorised" else "Inactive — tap to request",
            admin, T.GREEN) { checked ->
            if (checked) {
                ctx.startActivity(Intent(DevicePolicyManager.ACTION_ADD_DEVICE_ADMIN).apply {
                    putExtra(DevicePolicyManager.EXTRA_DEVICE_ADMIN,
                        android.content.ComponentName(ctx, CanaryDeviceAdminReceiver::class.java))
                    putExtra(DevicePolicyManager.EXTRA_ADD_EXPLANATION,
                        "Enable Canary Duress Lock to allow an emergency factory reset when the duress PIN is entered.")
                })
            }
            admin = checked
            rebuild()
        })

        val warn = hrow(ctx)
        warn.background = rounded(ctx, T.alpha(T.RED, 0.07f), 11f, T.alpha(T.RED, 0.2f))
        warn.setPadding(ctx.dpi(12f), ctx.dpi(11f), ctx.dpi(12f), ctx.dpi(11f))
        warn.gravity = Gravity.TOP
        warn.addView(text(ctx, "⚠", 12f, T.RED))
        warn.addView(hspacer(ctx, 9f))
        val warnText = vcol(ctx)
        warnText.addView(text(ctx, "Irreversible action warning", 10.5f, T.RED, bold = true))
        warnText.addView(text(
            ctx,
            "Purge operations permanently delete encryption keys from StrongBox. " +
                "Without an off-device backup the vault cannot be recovered.",
            9.5f, T.MUTED
        ).apply { setLineSpacing(ctx.spi(2f), 1f) })
        warn.addView(warnText, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        warn.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = ctx.dpi(14f); bottomMargin = ctx.dpi(14f) }
        body.addView(warn)

        root.addView(actionButton(ctx, "Save configuration", T.GREEN) {
            engine.setDuressAction(action)
            engine.setMockMode(mock)
            onSaved()
            dismiss()
        })

        return root
    }

    private fun rebuild() {
        // Recreate the content so toggles reflect their new state. Deferred out of
        // the touch event that triggered it to avoid swapping the hierarchy mid-dispatch.
        window?.decorView?.post {
            if (isShowing) setContentView(buildContent())
        }
    }

    private fun optionRow(value: Int, title: String, desc: String, selected: Boolean, accent: Int): LinearLayout {
        val row = hrow(ctx)
        row.background = rounded(
            ctx,
            if (selected) T.alpha(accent, 0.08f) else T.OBSIDIAN_LIGHT,
            12f,
            if (selected) accent else T.BORDER,
            if (selected) 1.5f else 1f
        )
        row.setPadding(ctx.dpi(12f), ctx.dpi(11f), ctx.dpi(12f), ctx.dpi(11f))
        row.addView(text(ctx, if (selected) "◉" else "○", 13f, if (selected) accent else T.MUTED))
        row.addView(hspacer(ctx, 10f))
        val box = vcol(ctx)
        box.addView(text(ctx, title, 12f, if (selected) T.TEXT else T.TEXT2, bold = true))
        box.addView(text(ctx, desc, 9.5f, T.MUTED).apply { setPadding(0, ctx.dpi(2f), 0, 0) })
        row.addView(box, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        row.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { bottomMargin = ctx.dpi(8f) }
        row.setOnClickListener {
            action = value
            rebuild()
        }
        return row
    }
}
