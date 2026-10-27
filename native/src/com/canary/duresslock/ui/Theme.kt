package com.canary.duresslock.ui

import android.content.Context
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.util.TypedValue
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.math.roundToInt

/** Cyber-stealth palette — mirrors lib/core/theme/app_theme.dart */
object T {
    val OBSIDIAN = 0xFF090A0Fu.toInt()
    val OBSIDIAN_LIGHT = 0xFF13151Eu.toInt()
    val PANEL = 0xFF1A1D2Bu.toInt()
    val CARD = 0xFF1E2235u.toInt()
    val BORDER = 0xFF2A2F4Au.toInt()

    val GREEN = 0xFF10B981u.toInt()
    val GREEN_DIM = 0xFF0D9468u.toInt()
    val RED = 0xFFEF4444u.toInt()
    val AMBER = 0xFFF59E0Bu.toInt()
    val BLUE = 0xFF3B82F6u.toInt()

    val TEXT = 0xFFF1F5F9u.toInt()
    val TEXT2 = 0xFF94A3B8u.toInt()
    val MUTED = 0xFF64748Bu.toInt()
    val GHOST = 0xFF475569u.toInt()

    val DECOY_BG = 0xFFF1F5F9u.toInt()
    val DECOY_CARD = 0xFFFFFFFFu.toInt()
    val DECOY_TEXT = 0xFF1E293Bu.toInt()
    val DECOY_MUTED = 0xFF94A3B8u.toInt()
    val DECOY_LINE = 0xFFE2E8F0u.toInt()
    val DECOY_ACCENT = 0xFF6366F1u.toInt()

    fun alpha(color: Int, a: Float): Int {
        val al = (a.coerceIn(0f, 1f) * 255f).roundToInt()
        return (color and 0x00FFFFFF) or (al shl 24)
    }
}

fun Context.dpi(v: Float): Int = (resources.displayMetrics.density * v).roundToInt()
fun Context.spi(v: Float): Float = TypedValue.applyDimension(
    TypedValue.COMPLEX_UNIT_SP, v, resources.displayMetrics
)

fun rounded(
    ctx: Context,
    fill: Int,
    radiusDp: Float,
    strokeColor: Int? = null,
    strokeWidthDp: Float = 1f
): GradientDrawable {
    val d = GradientDrawable()
    d.shape = GradientDrawable.RECTANGLE
    d.cornerRadius = ctx.dpi(radiusDp).toFloat()
    d.setColor(fill)
    if (strokeColor != null) d.setStroke(ctx.dpi(strokeWidthDp).coerceAtLeast(1), strokeColor)
    return d
}

fun circle(fill: Int, strokeColor: Int? = null, strokeWidth: Int = 0): GradientDrawable {
    val d = GradientDrawable()
    d.shape = GradientDrawable.OVAL
    d.setColor(fill)
    if (strokeColor != null && strokeWidth > 0) d.setStroke(strokeWidth, strokeColor)
    return d
}

/** Base text helper: every label in the app goes through this. */
fun text(
    ctx: Context,
    value: String,
    sizeSp: Float,
    color: Int,
    bold: Boolean = false,
    mono: Boolean = false,
    letterSpacing: Float = 0f
): TextView = TextView(ctx).apply {
    this.text = value
    setTextSize(TypedValue.COMPLEX_UNIT_SP, sizeSp)
    setTextColor(color)
    this.letterSpacing = letterSpacing
    typeface = when {
        mono -> Typeface.MONOSPACE
        bold -> Typeface.create("sans-serif-medium", Typeface.BOLD)
        else -> Typeface.create("sans-serif", Typeface.NORMAL)
    }
    includeFontPadding = false
}

fun vcol(ctx: Context): LinearLayout = LinearLayout(ctx).apply {
    orientation = LinearLayout.VERTICAL
}

fun hrow(ctx: Context): LinearLayout = LinearLayout(ctx).apply {
    orientation = LinearLayout.HORIZONTAL
    gravity = android.view.Gravity.CENTER_VERTICAL
}

fun spacer(ctx: Context, h: Float): android.view.View = android.view.View(ctx).apply {
    layoutParams = LinearLayout.LayoutParams(1, ctx.dpi(h))
}

fun hspacer(ctx: Context, w: Float): android.view.View = android.view.View(ctx).apply {
    layoutParams = LinearLayout.LayoutParams(ctx.dpi(w), 1)
}

/** Dark panel with hairline border — the app's core surface. */
fun panel(
    ctx: Context,
    radius: Float = 16f,
    fill: Int = T.PANEL,
    stroke: Int? = T.BORDER,
    padding: Float = 14f
): LinearLayout = vcol(ctx).apply {
    background = rounded(ctx, fill, radius, stroke)
    setPadding(ctx.dpi(padding), ctx.dpi(padding), ctx.dpi(padding), ctx.dpi(padding))
}

fun sectionLabel(ctx: Context, value: String): TextView = text(
    ctx, value.uppercase(), 9f, T.GHOST, bold = true, letterSpacing = 0.12f
).apply {
    setPadding(ctx.dpi(2f), ctx.dpi(16f), 0, ctx.dpi(8f))
}
