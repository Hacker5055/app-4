# Web preview — Canary Duress Lock

A dependency-light React + Vite simulation of the Flutter app: same palette, same copy, same
duress sequence. Used to review the UX and the exact native call ordering without building an APK.

```bash
npm install
npm run dev      # http://localhost:5173 (bound to 0.0.0.0)
npm run build    # static bundle in dist/
```

Flows covered:

| Flow | How to reach it |
|---|---|
| Lock gate + keypad | default screen |
| First-launch wizard (master → duress → action) | side panel → **Setup wizard** |
| Wrong PIN + 5-attempt lockout | type any wrong 6 digits five times |
| Real vault | master PIN `123456` |
| Duress configuration sheet | shield icon in the vault, or `CONFIG` on the mock banner |
| Mock purge log → decoy hand-off | duress PIN `654321` with mock mode on |
| Silent purge → decoy | duress PIN with mock mode off |
| Exit decoy | tap the **Smart Tools** title five times |
| Reset demo state | side panel → **Reset demo** |

The side console mirrors the Dart `DuressExecutionLog` entries so the sequence can be reviewed
against `lib/core/services/duress_service.dart`.
