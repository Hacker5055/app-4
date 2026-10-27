package com.canary.duresslock.ui

import android.content.Context
import android.util.TypedValue
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.TextView

/**
 * Six-digit PIN entry: dots + message line + numeric keypad.
 * Used by the lock gate and by both steps of the first-launch wizard.
 */
class PinPad(
    ctx: Context,
    private var onComplete: (String) -> Unit
) : LinearLayout(ctx) {

    val dots = PinDotsView(ctx)
    private val message = text(ctx, "Enter 6 digits", 11f, T.MUTED)
    private val pin = StringBuilder()
    private var inputEnabled = true
    private val keys = ArrayList<KeyView>()

    init {
        orientation = VERTICAL
        gravity = Gravity.CENTER_HORIZONTAL

        dots.layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT).apply {
            topMargin = ctx.dpi(22f)
        }
        addView(dots)

        message.gravity = Gravity.CENTER
        message.layoutParams = LayoutParams(LayoutParams.MATCH_PARENT, ctx.dpi(34f)).apply {
            topMargin = ctx.dpi(8f)
            leftMargin = ctx.dpi(20f)
            rightMargin = ctx.dpi(20f)
        }
        addView(message)

        val rows = listOf(
            listOf("1" to "", "2" to "ABC", "3" to "DEF"),
            listOf("4" to "GHI", "5" to "JKL", "6" to "MNO"),
            listOf("7" to "PQRS", "8" to "TUV", "9" to "WXYZ"),
            listOf("clear" to "", "0" to "+", "back" to "")
        )

        for (row in rows) {
            val rowView = hrow(ctx)
            rowView.gravity = Gravity.CENTER
            rowView.layoutParams = LayoutParams(LayoutParams.WRAP_CONTENT, LayoutParams.WRAP_CONTENT)
            for ((label, sub) in row) {
                val key = when (label) {
                    "clear" -> KeyView(ctx, "CLEAR") { clear() }.apply { layoutParams = keyParams(ctx) }
                    "back" -> KeyView(ctx, "⌫") { backspace() }.apply { layoutParams = keyParams(ctx) }
                    else -> KeyView(ctx, label, sub) { append(label) }
                }
                keys.add(key)
                rowView.addView(key)
            }
            addView(rowView)
        }
    }

    private fun keyParams(ctx: Context): LayoutParams = LayoutParams(ctx.dpi(66f), ctx.dpi(66f)).apply {
        marginStart = ctx.dpi(10f)
        marginEnd = ctx.dpi(10f)
        topMargin = ctx.dpi(6f)
        bottomMargin = ctx.dpi(6f)
    }

    fun reset() {
        pin.setLength(0)
        dots.filled = 0
        dots.isError = false
        message.text = "Enter 6 digits"
        message.setTextColor(T.MUTED)
    }

    fun showError(value: String) {
        dots.isError = true
        message.text = value
        message.setTextColor(T.RED)
        dots.animate().translationX(0f).setDuration(60).withEndAction {
            dots.translationX = 0f
            shake()
        }.start()
    }

    private fun shake() {
        val seq = android.animation.ObjectAnimator.ofFloat(dots, "translationX", 0f, -9f, 9f, -6f, 6f, 0f)
        seq.duration = 380
        seq.start()
    }

    fun showInfo(value: String) {
        message.text = value
        message.setTextColor(T.MUTED)
    }

    fun setInputEnabled(enabled: Boolean) {
        inputEnabled = enabled
        for (k in keys) {
            k.isEnabled = enabled
            k.alpha = if (enabled) 1f else 0.45f
        }
    }

    private fun append(digit: String) {
        if (!inputEnabled) return
        if (pin.length >= 6) return
        pin.append(digit)
        dots.filled = pin.length
        if (pin.length == 6) {
            val value = pin.toString()
            postDelayed({ if (pin.length == 6) onComplete(value) }, 140)
        }
    }

    private fun backspace() {
        if (!inputEnabled) return
        if (pin.isEmpty()) return
        pin.setLength(pin.length - 1)
        dots.filled = pin.length
    }

    private fun clear() {
        if (!inputEnabled) return
        pin.setLength(0)
        dots.filled = 0
        dots.isError = false
        message.text = ""
    }
}
