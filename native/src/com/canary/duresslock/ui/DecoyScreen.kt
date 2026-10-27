package com.canary.duresslock.ui

import android.app.AlertDialog
import android.content.Context
import android.view.Gravity
import android.view.View
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.ScrollView

/**
 * Decoy environment: a plain utility app (Calculator · Notes · Gallery).
 * Tapping the "Smart Tools" title five times is the only way back out.
 */
class DecoyScreen(ctx: Context, private val onExit: () -> Unit) : LinearLayout(ctx) {

    private val content = FrameLayout(ctx)
    private val tabButtons = ArrayList<LinearLayout>()
    private var tab = 0
    private var taps = 0
    private var bannerShown = true
    private var notes = mutableListOf(
        Triple("Grocery List", "Milk, bread, eggs, tomatoes, basil", "Oct 24"),
        Triple("Meeting Notes", "Discuss Q4 roadmap with the team", "Oct 22"),
        Triple("Recipe — Koshari", "Rice, lentils, pasta, tomato sauce", "Oct 20"),
        Triple("Workout Plan", "Mon: chest · Tue: back · Wed: legs", "Oct 18")
    )

    private val calc = DecoyCalculator(ctx)

    init {
        orientation = VERTICAL
        setBackgroundColor(T.DECOY_BG)

        // ── top bar ──
        val top = vcol(ctx)
        top.setBackgroundColor(T.DECOY_CARD)
        top.setPadding(ctx.dpi(14f), ctx.dpi(12f), ctx.dpi(14f), 0)

        val titleRow = hrow(ctx)
        val icon = text(ctx, "🧮", 15f, T.DECOY_ACCENT)
        icon.gravity = Gravity.CENTER
        icon.background = rounded(ctx, T.alpha(T.DECOY_ACCENT, 0.12f), 8f)
        icon.layoutParams = LinearLayout.LayoutParams(ctx.dpi(30f), ctx.dpi(30f))
        titleRow.addView(icon)
        titleRow.addView(hspacer(ctx, 9f))
        val titleBox = vcol(ctx)
        val title = text(ctx, "Smart Tools", 13.5f, T.DECOY_TEXT, bold = true)
        title.setOnClickListener { onSecretTap() }
        titleBox.addView(title)
        titleBox.addView(text(ctx, "Calculator · Notes · Gallery", 9f, T.DECOY_MUTED))
        titleRow.addView(titleBox, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        titleRow.addView(text(ctx, "🔍", 13f, T.DECOY_MUTED))
        titleRow.addView(hspacer(ctx, 12f))
        titleRow.addView(text(ctx, "⋮", 15f, T.DECOY_MUTED))
        top.addView(titleRow)

        // ── tabs ──
        val tabs = LinearLayout(ctx).apply {
            orientation = HORIZONTAL
            setPadding(0, ctx.dpi(8f), 0, 0)
        }
        val labels = listOf("🧮" to "Calculator", "📝" to "Notes", "🖼" to "Gallery")
        for ((idx, item) in labels.withIndex()) {
            val tabView = vcol(ctx)
            tabView.gravity = Gravity.CENTER
            tabView.setPadding(0, ctx.dpi(6f), 0, ctx.dpi(8f))
            tabView.addView(text(ctx, item.first, 14f, T.DECOY_ACCENT).apply { gravity = Gravity.CENTER })
            tabView.addView(text(ctx, item.second, 10f, T.DECOY_ACCENT, bold = true).apply {
                gravity = Gravity.CENTER
                setPadding(0, ctx.dpi(3f), 0, 0)
            })
            tabView.layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            tabView.setOnClickListener { selectTab(idx) }
            tabButtons.add(tabView)
            tabs.addView(tabView)
        }
        top.addView(tabs)
        addView(top, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))

        // ── content ──
        content.layoutParams = LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, 0, 1f)
        addView(content)

        // ── bottom nav ──
        val nav = LinearLayout(ctx).apply {
            orientation = HORIZONTAL
            setBackgroundColor(T.DECOY_CARD)
            setPadding(0, ctx.dpi(8f), 0, ctx.dpi(9f))
        }
        for ((i, label) in listOf("Home", "History", "Profile", "Settings").withIndex()) {
            val item = vcol(ctx)
            item.gravity = Gravity.CENTER
            item.addView(text(ctx, listOf("🏠", "🕘", "👤", "⚙")[i], 13f, T.DECOY_MUTED).apply { gravity = Gravity.CENTER })
            item.addView(text(ctx, label, 9f, T.DECOY_MUTED).apply {
                gravity = Gravity.CENTER
                setPadding(0, ctx.dpi(3f), 0, 0)
            })
            item.layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            nav.addView(item)
        }
        addView(nav, LinearLayout.LayoutParams(LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT))

        selectTab(0)
    }

    private fun selectTab(index: Int) {
        tab = index
        for ((i, view) in tabButtons.withIndex()) {
            val accent = if (i == index) T.DECOY_ACCENT else T.DECOY_MUTED
            (view.getChildAt(0) as android.widget.TextView).setTextColor(accent)
            (view.getChildAt(1) as android.widget.TextView).setTextColor(accent)
            view.background = null
        }
        content.removeAllViews()
        val body: View = when (index) {
            1 -> buildNotes()
            2 -> buildGallery()
            else -> calc
        }
        content.addView(body, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.MATCH_PARENT
        ))
    }

    // ── Notes ──
    private fun buildNotes(): View {
        val ctx = context
        val scroll = ScrollView(ctx)
        scroll.setBackgroundColor(T.DECOY_BG)
        val col = vcol(ctx)
        col.setPadding(ctx.dpi(11f), ctx.dpi(10f), ctx.dpi(11f), ctx.dpi(12f))
        scroll.addView(col, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT
        ))

        val search = hrow(ctx)
        search.background = rounded(ctx, T.DECOY_CARD, 10f, T.DECOY_LINE)
        search.setPadding(ctx.dpi(12f), ctx.dpi(10f), ctx.dpi(12f), ctx.dpi(10f))
        search.addView(text(ctx, "🔍", 11f, T.DECOY_MUTED))
        search.addView(hspacer(ctx, 8f))
        search.addView(text(ctx, "Search notes…", 11.5f, T.DECOY_MUTED))
        search.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { bottomMargin = ctx.dpi(10f) }
        col.addView(search)

        val colors = listOf(0xFF6366F1u.toInt(), 0xFF10B981u.toInt(), 0xFFF59E0Bu.toInt(), 0xFFEF4444u.toInt())
        for ((i, note) in notes.withIndex()) {
            val card = hrow(ctx)
            card.background = rounded(ctx, T.DECOY_CARD, 12f, T.DECOY_LINE)
            card.setPadding(ctx.dpi(12f), ctx.dpi(12f), ctx.dpi(12f), ctx.dpi(12f))
            val badge = text(ctx, "📝", 13f, colors[i % colors.size])
            badge.gravity = Gravity.CENTER
            badge.background = rounded(ctx, T.alpha(colors[i % colors.size], 0.12f), 9f)
            badge.layoutParams = LinearLayout.LayoutParams(ctx.dpi(36f), ctx.dpi(36f))
            card.addView(badge)
            card.addView(hspacer(ctx, 11f))
            val meta = vcol(ctx)
            meta.addView(text(ctx, note.first, 12.5f, T.DECOY_TEXT, bold = true))
            meta.addView(text(ctx, note.second, 10.5f, T.DECOY_MUTED).apply { setPadding(0, ctx.dpi(2f), 0, 0) })
            card.addView(meta, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
            card.addView(text(ctx, note.third, 10f, T.DECOY_MUTED))
            card.layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = ctx.dpi(9f) }
            col.addView(card)

            if (!bannerShown) break
        }

        col.addView(actionButton(ctx, "＋  New note", T.DECOY_ACCENT, 0xFFFFFFFFu.toInt()) {
            notes.add(0, Triple("New note", "Tap to edit this note…", "Today"))
            selectTab(1)
        })
        return scroll
    }

    // ── Gallery ──
    private fun buildGallery(): View {
        val ctx = context
        val scroll = ScrollView(ctx)
        scroll.setBackgroundColor(T.DECOY_BG)
        val col = vcol(ctx)
        col.setPadding(ctx.dpi(11f), ctx.dpi(10f), ctx.dpi(11f), ctx.dpi(12f))
        scroll.addView(col, FrameLayout.LayoutParams(
            FrameLayout.LayoutParams.MATCH_PARENT, FrameLayout.LayoutParams.WRAP_CONTENT
        ))

        val stats = hrow(ctx)
        stats.addView(text(ctx, "1,248 photos · 12 videos", 10.5f, T.DECOY_MUTED))
        stats.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { bottomMargin = ctx.dpi(9f) }
        col.addView(stats)

        val photos = listOf(
            "Sunset at Nile" to ("☀" to 0xFFFEF3C7u.toInt()),
            "Family Dinner" to ("👨‍👩‍👧" to 0xFFD1FAE5u.toInt()),
            "Cats in Garden" to ("🐈" to 0xFFDBEAFEu.toInt()),
            "Beach Day" to ("🏖" to 0xFFFCE7F3u.toInt()),
            "Birthday Cake" to ("🎂" to 0xFFE0E7FFu.toInt()),
            "Graduation" to ("🎓" to 0xFFFED7AAu.toInt())
        )
        for (chunk in photos.chunked(3)) {
            val rowView = LinearLayout(ctx).apply { orientation = HORIZONTAL }
            for (p in chunk) {
                val tile = vcol(ctx)
                tile.gravity = Gravity.CENTER
                tile.background = rounded(ctx, p.second.second, 10f, T.DECOY_LINE)
                tile.setPadding(ctx.dpi(3f), ctx.dpi(16f), ctx.dpi(3f), ctx.dpi(16f))
                tile.addView(text(ctx, p.second.first, 19f, T.DECOY_TEXT).apply { gravity = Gravity.CENTER })
                tile.addView(text(ctx, p.first, 8f, T.DECOY_TEXT, bold = true).apply {
                    gravity = Gravity.CENTER
                    setPadding(0, ctx.dpi(4f), 0, 0)
                    maxLines = 1
                })
                tile.layoutParams = LinearLayout.LayoutParams(0, ctx.dpi(88f), 1f).apply {
                    marginEnd = ctx.dpi(7f)
                }
                rowView.addView(tile)
            }
            col.addView(rowView, LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { bottomMargin = ctx.dpi(7f) })
        }

        // recent calls — benign inspection bait
        val calls = vcol(ctx)
        calls.background = rounded(ctx, T.DECOY_CARD, 12f, T.DECOY_LINE)
        calls.setPadding(ctx.dpi(12f), ctx.dpi(12f), ctx.dpi(12f), ctx.dpi(12f))
        val callHead = hrow(ctx)
        callHead.addView(text(ctx, "📞", 12f, 0xFF3B82F6u.toInt()))
        callHead.addView(hspacer(ctx, 7f))
        callHead.addView(text(ctx, "Recent calls", 11.5f, T.DECOY_TEXT, bold = true))
        calls.addView(callHead)
        val logs = listOf(
            Triple("Mom", "Today 09:12", "2:34"),
            Triple("Ahmed — Work", "Yesterday 16:45", "5:12"),
            Triple("+20 100 123 4567", "Yesterday 11:20", ""),
            Triple("Sarah", "Oct 24 14:30", "1:05")
        )
        for (log in logs) {
            val row = hrow(ctx)
            row.setPadding(0, ctx.dpi(10f), 0, 0)
            val av = text(ctx, "📞", 10f, T.DECOY_MUTED)
            av.gravity = Gravity.CENTER
            av.background = circle(0xFFF1F5F9u.toInt())
            av.layoutParams = LinearLayout.LayoutParams(ctx.dpi(28f), ctx.dpi(28f))
            row.addView(av)
            row.addView(hspacer(ctx, 9f))
            val meta = vcol(ctx)
            meta.addView(text(ctx, log.first, 11.5f, T.DECOY_TEXT, bold = true))
            meta.addView(text(ctx, log.second, 9.5f, T.DECOY_MUTED))
            row.addView(meta, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
            row.addView(text(ctx, log.third, 9.5f, T.DECOY_MUTED))
            calls.addView(row)
        }
        calls.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = ctx.dpi(4f) }
        col.addView(calls)
        return scroll
    }

    private fun onSecretTap() {
        taps++
        if (taps >= 5) {
            taps = 0
            AlertDialog.Builder(context)
                .setTitle("Exit decoy?")
                .setMessage("Return to the lock screen? Your PIN will be required again.")
                .setNegativeButton("Cancel", null)
                .setPositiveButton("Exit") { _, _ -> onExit() }
                .show()
        }
        postDelayed({ taps = 0 }, 2500)
    }
}
