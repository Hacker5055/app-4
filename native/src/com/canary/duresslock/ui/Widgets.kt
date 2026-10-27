package com.canary.duresslock.ui

import android.content.Context
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Path
import android.util.TypedValue
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.widget.LinearLayout
import android.widget.TextView
import kotlin.math.min

/** Shield emblem with neon glow — the app's identity mark. */
class ShieldView(ctx: Context, private val accent: Int = T.GREEN) : View(ctx) {
    private fun dp(v: Float): Int = context.dpi(v)
    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    private val path = Path()

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val size = dp(84f)
        setMeasuredDimension(size, size)
    }

    override fun onDraw(canvas: Canvas) {
        val w = width.toFloat()
        val h = height.toFloat()
        val cx = w / 2f
        val cy = h / 2f
        val r = min(w, h) / 2f

        // outer halo
        p.style = Paint.Style.FILL
        p.color = T.alpha(accent, 0.10f)
        canvas.drawCircle(cx, cy, r, p)

        p.style = Paint.Style.STROKE
        p.strokeWidth = dp(1.2f).toFloat()
        p.color = T.alpha(accent, 0.28f)
        canvas.drawCircle(cx, cy, r - p.strokeWidth / 2f, p)

        // inner puck
        p.style = Paint.Style.FILL
        p.color = T.PANEL
        canvas.drawCircle(cx, cy, r * 0.76f, p)
        p.style = Paint.Style.STROKE
        p.strokeWidth = dp(1.2f).toFloat()
        p.color = T.alpha(accent, 0.45f)
        canvas.drawCircle(cx, cy, r * 0.76f - p.strokeWidth / 2f, p)

        // shield glyph
        val s = r * 0.42f
        path.reset()
        path.moveTo(cx, cy - s * 1.15f)
        path.lineTo(cx + s, cy - s * 0.72f)
        path.lineTo(cx + s, cy + s * 0.12f)
        path.cubicTo(cx + s, cy + s * 0.9f, cx, cy + s * 1.15f, cx, cy + s * 1.15f)
        path.cubicTo(cx, cy + s * 1.15f, cx - s, cy + s * 0.9f, cx - s, cy + s * 0.12f)
        path.lineTo(cx - s, cy - s * 0.72f)
        path.close()

        p.style = Paint.Style.STROKE
        p.strokeWidth = dp(1.8f).toFloat()
        p.strokeJoin = Paint.Join.ROUND
        p.color = accent
        canvas.drawPath(path, p)

        // check mark
        p.strokeWidth = dp(1.9f).toFloat()
        p.strokeCap = Paint.Cap.ROUND
        val ck = Path()
        ck.moveTo(cx - s * 0.36f, cy - s * 0.05f)
        ck.lineTo(cx - s * 0.05f, cy + s * 0.3f)
        ck.lineTo(cx + s * 0.42f, cy - s * 0.42f)
        canvas.drawPath(ck, p)
    }
}

/** Six-dot PIN indicator. */
class PinDotsView(ctx: Context) : View(ctx) {
    private fun dp(v: Float): Int = context.dpi(v)
    private val p = Paint(Paint.ANTI_ALIAS_FLAG)
    var filled: Int = 0
        set(v) { field = v; invalidate() }
    var isError: Boolean = false
        set(v) { field = v; invalidate() }

    private val dotDp = 15f
    private val gapDp = 16f

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        val total = dp((dotDp * 6 + gapDp * 5).toInt().toFloat())
        setMeasuredDimension(total, dp(dotDp + 6f))
    }

    override fun onDraw(canvas: Canvas) {
        val d = dp(dotDp).toFloat()
        val g = dp(gapDp).toFloat()
        val cy = height / 2f
        val active = if (isError) T.RED else T.GREEN
        for (i in 0 until 6) {
            val cx = d / 2f + i * (d + g)
            val isFilled = i < filled
            if (isFilled) {
                p.style = Paint.Style.FILL
                p.color = active
                canvas.drawCircle(cx, cy, d / 2f, p)
            } else {
                p.style = Paint.Style.STROKE
                p.strokeWidth = dp(1.4f).toFloat()
                p.color = if (i == filled) T.alpha(T.GREEN, 0.5f) else T.BORDER
                canvas.drawCircle(cx, cy, d / 2f - p.strokeWidth / 2f, p)
            }
        }
    }
}

/** Circular keypad key with optional sub-label. */
class KeyView(
    ctx: Context,
    primary: String,
    secondary: String? = null,
    private val accentOnPress: Boolean = true,
    private val onTap: () -> Unit
) : LinearLayout(ctx) {

    private fun dp(v: Float): Int = context.dpi(v)

    init {
        orientation = VERTICAL
        gravity = Gravity.CENTER
        background = circle(T.PANEL, T.alpha(T.BORDER, 0.7f), dp(1f))
        isClickable = true
        isFocusable = true
        layoutParams = LayoutParams(dp(66f), dp(66f)).apply {
            marginStart = dp(10f); marginEnd = dp(10f)
            topMargin = dp(6f); bottomMargin = dp(6f)
        }
        addView(text(ctx, primary, if (primary.length > 2) 12f else 23f, T.TEXT, bold = primary.length > 2))
        if (!secondary.isNullOrEmpty()) {
            addView(text(ctx, secondary, 8f, T.GHOST, bold = true, letterSpacing = 0.12f).apply {
                setPadding(0, dp(2f), 0, 0)
            })
        }
        setOnClickListener { animate().scaleX(0.94f).scaleY(0.94f).setDuration(80).withEndAction {
            animate().scaleX(1f).scaleY(1f).setDuration(90).start()
            onTap()
        }.start() }
    }

    override fun onTouchEvent(event: MotionEvent): Boolean {
        when (event.actionMasked) {
            MotionEvent.ACTION_DOWN -> background = circle(
                if (accentOnPress) T.alpha(T.GREEN, 0.16f) else T.OBSIDIAN_LIGHT,
                T.alpha(T.GREEN, 0.55f), dp(1f)
            )
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> background = circle(
                T.PANEL, T.alpha(T.BORDER, 0.7f), dp(1f)
            )
        }
        return super.onTouchEvent(event)
    }
}

/** Rounded primary action button. */
fun actionButton(
    ctx: Context,
    label: String,
    fill: Int = T.GREEN,
    textColor: Int = T.OBSIDIAN,
    enabled: Boolean = true,
    onClick: () -> Unit
): TextView = text(ctx, label.uppercase(), 12f, textColor, bold = true, letterSpacing = 0.08f).apply {
    gravity = Gravity.CENTER
    setPadding(ctx.dpi(18f), ctx.dpi(15f), ctx.dpi(18f), ctx.dpi(15f))
    background = rounded(ctx, if (enabled) fill else T.alpha(fill, 0.4f), 12f)
    isClickable = enabled
    if (enabled) setOnClickListener { onClick() }
}

/** Small outlined pill (category filter / info chip). */
fun chip(
    ctx: Context,
    label: String,
    selected: Boolean,
    accent: Int = T.GREEN,
    onClick: (() -> Unit)? = null
): TextView = text(
    ctx, label, 11f,
    if (selected) T.OBSIDIAN else T.TEXT2,
    bold = selected
).apply {
    setPadding(ctx.dpi(13f), ctx.dpi(7f), ctx.dpi(13f), ctx.dpi(7f))
    background = rounded(
        ctx,
        if (selected) accent else T.PANEL,
        20f,
        if (selected) accent else T.BORDER
    )
    if (onClick != null) setOnClickListener { onClick() }
}

/** Status stat card used on the vault header grid. */
fun statCard(ctx: Context, title: String, value: String, sub: String, accent: Int): LinearLayout {
    val box = panel(ctx, 13f, T.PANEL, T.BORDER, 12f)
    val head = hrow(ctx)
    val dot = View(ctx).apply {
        background = circle(T.alpha(accent, 0.16f), null, 0)
        layoutParams = LinearLayout.LayoutParams(ctx.dpi(8f), ctx.dpi(8f))
    }
    head.addView(dot)
    head.addView(hspacer(ctx, 7f))
    head.addView(text(ctx, title.uppercase(), 8f, T.GHOST, bold = true, letterSpacing = 0.1f))
    box.addView(head)
    box.addView(text(ctx, value, 13f, accent, bold = true, letterSpacing = 0.04f).apply {
        setPadding(0, ctx.dpi(9f), 0, 0)
    })
    box.addView(text(ctx, sub, 9f, T.MUTED).apply { setPadding(0, ctx.dpi(2f), 0, 0) })
    return box
}

/** Toggle row used in the configuration sheet. */
fun toggleRow(
    ctx: Context,
    title: String,
    subtitle: String,
    checked: Boolean,
    accent: Int,
    checkable: Boolean = true,
    onChanged: (Boolean) -> Unit
): LinearLayout {
    val row = panel(ctx, 11f, T.OBSIDIAN_LIGHT, T.BORDER, 12f)
    row.orientation = LinearLayout.HORIZONTAL
    row.gravity = Gravity.CENTER_VERTICAL
    val box = vcol(ctx)
    box.layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
    box.addView(text(ctx, title, 12f, T.TEXT, bold = true))
    box.addView(text(ctx, subtitle, 10f, if (checked) accent else T.MUTED).apply {
        setPadding(0, ctx.dpi(2f), 0, 0)
    })
    row.addView(box)

    val sw = android.widget.Switch(ctx).apply {
        isChecked = checked
        isEnabled = checkable
        buttonTintList = android.content.res.ColorStateList(
            arrayOf(intArrayOf(android.R.attr.state_checked), intArrayOf()),
            intArrayOf(accent, T.GHOST)
        )
        setOnCheckedChangeListener { _, v -> onChanged(v) }
    }
    row.addView(sw)
    return row
}

fun divider(ctx: Context): View = View(ctx).apply {
    setBackgroundColor(T.BORDER)
    layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 1)
}

/** Pulsing "live" dot label. */
fun livePill(ctx: Context, label: String, accent: Int = T.GREEN): LinearLayout {
    val row = hrow(ctx)
    val dot = View(ctx).apply {
        background = circle(accent, null, 0)
        layoutParams = LinearLayout.LayoutParams(ctx.dpi(6f), ctx.dpi(6f))
    }
    row.addView(dot)
    row.addView(hspacer(ctx, 6f))
    row.addView(text(ctx, label, 8f, accent, bold = true, letterSpacing = 0.14f))
    return row
}

fun dpToPx(ctx: Context, dp: Float) = ctx.dpi(dp)

fun monoBlock(ctx: Context, value: String, color: Int = T.TEXT2): TextView =
    text(ctx, value, 10f, color, mono = true).apply {
        setTextIsSelectable(true)
        setLineSpacing(ctx.spi(3f), 1f)
    }

fun transparentView(ctx: Context): View = View(ctx).apply { setBackgroundColor(Color.TRANSPARENT) }

fun pad(ctx: Context, v: View, l: Float = 0f, t: Float = 0f, r: Float = 0f, b: Float = 0f): View {
    v.setPadding(ctx.dpi(l), ctx.dpi(t), ctx.dpi(r), ctx.dpi(b))
    return v
}

fun textSizeSp(ctx: Context, sp: Float): Float = TypedValue.applyDimension(
    TypedValue.COMPLEX_UNIT_SP, sp, ctx.resources.displayMetrics
)
