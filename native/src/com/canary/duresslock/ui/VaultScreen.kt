package com.canary.duresslock.ui

import android.content.Context
import android.view.Gravity
import android.widget.LinearLayout
import android.widget.ScrollView
import com.canary.duresslock.DuressEngine

private data class VaultItem(val title: String, val category: String, val detail: String)

/**
 * Master vault. Only reachable after a verified master PIN.
 * Shows encrypted inventory, hardware status and the duress configuration entry point.
 */
class VaultScreen(
    ctx: Context,
    private val engine: DuressEngine,
    private val onLock: () -> Unit,
    private val onConfig: () -> Unit
) : ScrollView(ctx) {

    private val col = vcol(ctx)
    private var filter = "All"

    private val items = listOf(
        VaultItem("Passport Scan.pdf", "Documents", "AES-256-GCM · StrongBox"),
        VaultItem("Bank Credentials", "Credentials", "Hardware-backed · biometric"),
        VaultItem("Private Photos (12)", "Photos", "End-to-end encrypted · zero-knowledge"),
        VaultItem("Legal Documents", "Documents", "KeyStore protected · no backup"),
        VaultItem("Recovery Keys", "Credentials", "Master seed · never leaves device"),
        VaultItem("Trip Notes", "Notes", "Encrypted draft · 3 entries")
    )

    init {
        setBackgroundColor(T.OBSIDIAN)
        addView(col, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.WRAP_CONTENT))
        render()
    }

    private fun render() {
        val ctx = context
        col.removeAllViews()
        col.setPadding(0, ctx.dpi(22f), 0, ctx.dpi(24f))

        // ── header ──
        val header = hrow(ctx)
        header.setPadding(ctx.dpi(16f), 0, ctx.dpi(16f), ctx.dpi(14f))
        header.addView(text(ctx, "🛡", 16f, T.GREEN).apply {
            gravity = Gravity.CENTER
            background = rounded(ctx, T.PANEL, 10f, T.alpha(T.GREEN, 0.3f))
            layoutParams = LinearLayout.LayoutParams(ctx.dpi(34f), ctx.dpi(34f))
        })
        header.addView(hspacer(ctx, 10f))
        val titleBox = vcol(ctx)
        titleBox.addView(text(ctx, "CANARY VAULT", 13f, T.TEXT, bold = true, letterSpacing = 0.12f))
        titleBox.addView(text(ctx, "Hardware encrypted · StrongBox", 9f, T.GREEN))
        header.addView(titleBox, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        header.addView(iconButton(ctx, "⚙", T.TEXT2) { onConfig() })
        header.addView(hspacer(ctx, 8f))
        header.addView(iconButton(ctx, "🔒", T.RED) { onLock() })
        col.addView(header)

        // ── mock strip ──
        if (engine.isMockMode()) {
            val strip = hrow(ctx)
            strip.background = rounded(ctx, T.alpha(T.AMBER, 0.1f), 10f, T.alpha(T.AMBER, 0.25f))
            strip.setPadding(ctx.dpi(12f), ctx.dpi(9f), ctx.dpi(12f), ctx.dpi(9f))
            strip.addView(text(ctx, "MOCK TESTING — PURGES ARE SIMULATED", 9.5f, T.AMBER, bold = true))
            strip.layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { leftMargin = ctx.dpi(16f); rightMargin = ctx.dpi(16f); bottomMargin = ctx.dpi(12f) }
            strip.setOnClickListener { onConfig() }
            col.addView(strip)
        }

        // ── stat grid ──
        val keyInfo = engine.keyInfo()
        val hardware = when {
            keyInfo == null -> "SOFTWARE"
            keyInfo["isStrongBoxBacked"] == true -> "STRONGBOX"
            keyInfo["insideSecureHardware"] == true -> "TEE"
            else -> "SOFTWARE"
        }

        val grid1 = hrow(ctx)
        grid1.setPadding(ctx.dpi(16f), 0, ctx.dpi(16f), 0)
        grid1.addView(statCard(ctx, "Vault status", "ENCRYPTED", "AES-256-GCM", T.GREEN),
            LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        grid1.addView(hspacer(ctx, 10f))
        grid1.addView(statCard(ctx, "Key location", hardware, "AndroidKeyStore", if (hardware == "SOFTWARE") T.AMBER else T.BLUE),
            LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        col.addView(grid1)

        val grid2 = hrow(ctx)
        grid2.setPadding(ctx.dpi(16f), 0, ctx.dpi(16f), 0)
        grid2.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { topMargin = ctx.dpi(10f) }
        val armed = engine.duressCount() == 0
        grid2.addView(
            statCard(
                ctx, "Duress pin", if (armed) "ARMED" else "FIRED",
                DuressEngine.actionLabel(engine.duressAction()).substringBefore(" —"),
                if (armed) T.AMBER else T.RED
            ),
            LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
        )
        grid2.addView(hspacer(ctx, 10f))
        grid2.addView(statCard(ctx, "Items secured", "${items.size}", "Zero-knowledge", T.GREEN),
            LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
        col.addView(grid2)

        // ── category chips ──
        val chips = hrow(ctx)
        chips.setPadding(ctx.dpi(16f), ctx.dpi(14f), ctx.dpi(16f), ctx.dpi(6f))
        for (c in listOf("All", "Photos", "Documents", "Credentials", "Notes")) {
            val chipView = chip(ctx, c, filter == c) {
                filter = c
                render()
            }
            chipView.layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT, LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { marginEnd = ctx.dpi(7f) }
            chips.addView(chipView)
        }
        col.addView(chips)

        // ── items ──
        val shown = if (filter == "All") items else items.filter { it.category == filter }
        for (item in shown) {
            val row = hrow(ctx)
            row.background = rounded(ctx, T.PANEL, 13f, T.BORDER)
            row.setPadding(ctx.dpi(12f), ctx.dpi(12f), ctx.dpi(12f), ctx.dpi(12f))
            val badge = text(ctx, categoryGlyph(item.category), 15f, T.GREEN)
            badge.gravity = Gravity.CENTER
            badge.background = rounded(ctx, T.OBSIDIAN_LIGHT, 10f, T.BORDER)
            badge.layoutParams = LinearLayout.LayoutParams(ctx.dpi(40f), ctx.dpi(40f))
            row.addView(badge)
            row.addView(hspacer(ctx, 12f))
            val meta = vcol(ctx)
            meta.addView(text(ctx, item.title, 12.5f, T.TEXT, bold = true))
            meta.addView(text(ctx, item.detail, 10f, T.MUTED).apply { setPadding(0, ctx.dpi(2f), 0, 0) })
            val tagRow = hrow(ctx)
            tagRow.setPadding(0, ctx.dpi(5f), 0, 0)
            tagRow.addView(text(ctx, item.category, 8.5f, T.GHOST, bold = true).apply {
                setPadding(ctx.dpi(5f), ctx.dpi(2f), ctx.dpi(5f), ctx.dpi(2f))
                background = rounded(ctx, T.OBSIDIAN, 4f)
            })
            tagRow.addView(hspacer(ctx, 6f))
            tagRow.addView(text(ctx, "🔒 encrypted", 8.5f, T.GREEN, bold = true))
            meta.addView(tagRow)
            row.addView(meta, LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f))
            row.layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply { leftMargin = ctx.dpi(16f); rightMargin = ctx.dpi(16f); topMargin = ctx.dpi(9f) }
            col.addView(row)
        }

        // ── encryption panel ──
        val info = panel(ctx, 14f, T.PANEL, T.alpha(T.GREEN, 0.22f), 14f)
        val infoHead = hrow(ctx)
        infoHead.addView(livePill(ctx, "ACTIVE"))
        infoHead.addView(hspacer(ctx, 8f))
        infoHead.addView(text(ctx, "End-to-end encryption", 11.5f, T.TEXT, bold = true))
        info.addView(infoHead)
        info.addView(text(
            ctx,
            "Vault contents are sealed with AES-256-GCM using a key held in AndroidKeyStore. " +
                "Key material never leaves secure hardware — and is destroyed on duress.",
            10.5f, T.MUTED
        ).apply {
            setPadding(0, ctx.dpi(9f), 0, 0)
            setLineSpacing(ctx.spi(2.5f), 1f)
        })
        info.layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT, LinearLayout.LayoutParams.WRAP_CONTENT
        ).apply { leftMargin = ctx.dpi(16f); rightMargin = ctx.dpi(16f); topMargin = ctx.dpi(14f) }
        col.addView(info)

        // ── footer ──
        col.addView(text(ctx, "PROTECTED BY CANARY DURESS LOCK", 8f, T.GHOST, letterSpacing = 0.14f).apply {
            gravity = Gravity.CENTER
            setPadding(0, ctx.dpi(20f), 0, ctx.dpi(3f))
        })
        col.addView(text(ctx, "Duress PIN purges keys — no recovery path", 8f, T.alpha(T.GHOST, 0.8f)).apply {
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, ctx.dpi(10f))
        })
    }

    private fun iconButton(
        ctx: Context,
        glyph: String,
        color: Int = T.TEXT2,
        onClick: () -> Unit
    ): android.widget.TextView =
        text(ctx, glyph, 14f, color).apply {
            gravity = Gravity.CENTER
            background = rounded(ctx, T.PANEL, 10f, T.BORDER)
            layoutParams = LinearLayout.LayoutParams(ctx.dpi(34f), ctx.dpi(34f))
            setOnClickListener { onClick() }
        }

    private fun categoryGlyph(cat: String): String = when (cat) {
        "Photos" -> "▣"
        "Documents" -> "▤"
        "Credentials" -> "🔑"
        "Notes" -> "▦"
        else -> "▢"
    }
}
