package com.canary.duresslock.ui

import android.content.Context
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Fully functional calculator — the primary decoy surface.
 * Real arithmetic, history, no trace of the vault.
 */
class DecoyCalculator(ctx: Context) : LinearLayout(ctx) {

    private val historyView = text(ctx, "", 12f, T.DECOY_MUTED)
    private val valueView = text(ctx, "0", 34f, T.DECOY_TEXT)
    private val historyPanel = vcol(ctx)

    private var display = "0"
    private var first: Double? = null
    private var op: String? = null
    private var awaiting = false
    private val past = mutableListOf<String>()

    init {
        orientation = VERTICAL
        setPadding(ctx.dpi(11f), ctx.dpi(4f), ctx.dpi(11f), ctx.dpi(8f))

        val displayPanel = vcol(ctx)
        displayPanel.background = rounded(ctx, T.DECOY_CARD, 18f, T.DECOY_LINE)
        displayPanel.setPadding(ctx.dpi(16f), ctx.dpi(14f), ctx.dpi(16f), ctx.dpi(14f))
        displayPanel.gravity = Gravity.END
        historyView.gravity = Gravity.END
        displayPanel.addView(historyView)
        valueView.gravity = Gravity.END
        displayPanel.addView(valueView)
        displayPanel.addView(historyPanel)
        addView(displayPanel)

        addView(spacer(ctx, 10f))

        val rows = listOf(
            listOf("AC" to "top", "±" to "top", "%" to "top", "÷" to "op"),
            listOf("7" to "", "8" to "", "9" to "", "×" to "op"),
            listOf("4" to "", "5" to "", "6" to "", "−" to "op"),
            listOf("1" to "", "2" to "", "3" to "", "+" to "op"),
            listOf("0" to "", "." to "", "⌫" to "", "=" to "eq")
        )

        for (row in rows) {
            val rowView = LinearLayout(ctx).apply {
                orientation = HORIZONTAL
                gravity = Gravity.CENTER
            }
            for ((label, style) in row) {
                rowView.addView(calcKey(label, style), LinearLayout.LayoutParams(0, ctx.dpi(58f), 1f).apply {
                    marginEnd = ctx.dpi(7f)
                    marginStart = ctx.dpi(0f)
                    topMargin = ctx.dpi(7f)
                })
            }
            addView(rowView)
        }
    }

    private fun calcKey(label: String, style: String): TextView {
        val ctx = context
        val bg = when (style) {
            "eq" -> T.DECOY_ACCENT
            "op" -> 0xFFEEF2FFu.toInt()
            "top" -> 0xFFF1F5F9u.toInt()
            else -> 0xFFF8FAFCu.toInt()
        }
        val fg = when (style) {
            "eq" -> 0xFFFFFFFFu.toInt()
            "op" -> T.DECOY_ACCENT
            else -> T.DECOY_TEXT
        }
        val size = when (style) {
            "eq" -> 20f
            "top" -> 15f
            else -> 18f
        }
        return text(ctx, label, size, fg, bold = style == "op" || style == "eq").apply {
            gravity = Gravity.CENTER
            background = rounded(ctx, bg, 14f)
            setOnClickListener { onKey(label) }
        }
    }

    private fun onKey(key: String) {
        when (key) {
            "AC" -> {
                display = "0"; first = null; op = null; awaiting = false
            }
            "⌫" -> display = if (display.length > 1) display.substring(0, display.length - 1) else "0"
            "±" -> if (display != "0") display = if (display.startsWith("-")) display.substring(1) else "-$display"
            "%" -> display = fmt((display.toDoubleOrNull() ?: 0.0) / 100.0)
            "." -> {
                if (awaiting) { display = "0."; awaiting = false }
                else if (!display.contains(".")) display += "."
            }
            "=" -> equals()
            "÷", "×", "−", "+" -> {
                first = display.toDoubleOrNull()
                op = key
                awaiting = true
            }
            else -> {
                if (awaiting) { display = key; awaiting = false }
                else if (display == "0") display = key
                else if (display.length < 12) display += key
            }
        }
        refresh()
    }

    private fun equals() {
        val a = first ?: return
        val b = display.toDoubleOrNull() ?: return
        val result = when (op) {
            "+" -> a + b
            "−" -> a - b
            "×" -> a * b
            "÷" -> if (b == 0.0) 0.0 else a / b
            else -> return
        }
        val out = fmt(result)
        past.add(0, "${fmt(a)} ${op ?: ""} ${fmt(b)} = $out")
        if (past.size > 3) past.removeAt(past.size - 1)
        display = out
        historyView.text = ""
        first = null
        op = null
        awaiting = false
        refresh()
    }

    private fun fmt(v: Double): String {
        if (v.isNaN() || v.isInfinite()) return "0"
        return if (v == v.toLong().toDouble()) v.toLong().toString()
        else String.format(java.util.Locale.US, "%.6f", v).trimEnd('0').trimEnd('.')
    }

    private fun refresh() {
        valueView.text = display
        historyView.text = if (op != null && awaiting) "${fmt(display.toDoubleOrNull() ?: 0.0)} $op" else ""
        historyPanel.removeAllViews()
        if (past.isNotEmpty()) {
            val line = android.view.View(context).apply {
                setBackgroundColor(T.DECOY_LINE)
                layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 1).apply {
                    topMargin = context.dpi(9f); bottomMargin = context.dpi(7f)
                }
            }
            historyPanel.addView(line)
            for (p in past) {
                historyPanel.addView(text(context, p, 10f, T.DECOY_MUTED).apply {
                    setPadding(0, context.dpi(1.5f), 0, 0)
                })
            }
        }
    }
}
