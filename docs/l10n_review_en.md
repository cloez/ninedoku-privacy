# English (_en) Localization Review

**Scope:** `lib/shared/l10n/app_strings.dart` — `_en` block (lines 816–end).
**Reviewer voice:** mobile-app/puzzle-game UX writer.

## 1. Overall score: 7.5 / 10

The copy is largely clear, concise, and idiomatic. Casing is inconsistent (mix of Title Case and sentence case across siblings), and a handful of badge/strings read as literal translations from Korean. Tutorial and onboarding text is strong. With ~15 surgical edits, this set easily reaches 9/10.

## 2. Strong categories

- **Tutorial / Onboarding** (`tutorial.*`, `onboarding.*`) — natural, friendly, instructional voice.
- **Settings descriptions** (`settings.*.desc`) — concise and benefit-led.
- **Core gameplay verbs** (`game.pause`, `game.hint`, `game.undo`) — standard category terminology.
- **Rules text** (`futoshiki.rules.*`, `kakuro.rules.*`, `lightUp.rules.*`) — clean, accurate.

## 3. P0 — Immediate fixes (5 most unnatural)

| # | Key | Current | Suggested |
|---|---|---|---|
| 1 | `badge.binairo_master.name` | `Master Conquest` | `Master Conqueror` (matches `badge.diffMaster`; "Conquest" is the act, not the title) |
| 2 | `home.progress` | `% Complete` | `Complete` (the `%` is rendered numerically — current reads as "percent-sign Complete") |
| 3 | `pause.home` | `Home (Auto Save)` | `Home — auto-saved` (label, not a section heading; current reads as a window title) |
| 4 | `donation.message` | `If you enjoy this app,\nplease support the developer!` | `Enjoying the app?\nConsider supporting the developer.` (less pleading, mobile-friendly) |
| 5 | `result.grade.s` | `S: 0 mistakes · 0 hints · under ` | `S — no mistakes, no hints, under ` ("0 mistakes" reads numeric; rule-of-three flows better) |

## 4. P1 — Gradual fixes (max 10)

| # | Key | Current | Suggested |
|---|---|---|---|
| 1 | `home.newGame` | `New Game` | `New game` (sentence case — matches `futoshiki.newGame.warning.title`) |
| 2 | `home.todayPuzzle` / `daily.title` | `Today's Puzzle` | `Today's puzzle` (sentence case throughout) |
| 3 | `mode.comingSoon` | `Coming Soon` | `Coming soon` |
| 4 | `result.title` | `Game Complete` | `Puzzle complete` (category-standard; "game" is ambiguous in a hub) |
| 5 | `result.newGame` | `Play Again` | `Play again` |
| 6 | `stats.empty` | `No completed games yet` | `No completed puzzles yet` (consistent with category) |
| 7 | `badge.binairo_no_hint.name` | `Independent Solver` | `Solo Solver` (mirrors `badge.noHint` = "Self Solver") |
| 8 | `binairo.rules.r2` | `No more than two of the same color can be adjacent in a row.` | `No three of the same color in a row or column.` (clearer, mirrors standard Binairo phrasing) |
| 9 | `donation.ad.desc` | `Check out the developer's recommended product` | `A product the developer recommends` |
| 10 | `settings.autoComplete.desc` | `Auto-fill when all remaining cells are determined` | `Auto-fill when only one solution remains` |

## 5. Tone consistency

- **Casing:** mixed Title Case ("New Game", "Game Complete", "Play Again") vs. sentence case ("Game in progress", "Give up?"). Pick **sentence case** for all button labels, dialog titles, and section headers — current Android/iOS guidance and matches the newer (auto-added) keys.
- **Voice:** mostly friendly second-person. A few imperative-but-stiff lines (`pause.home`, `donation.message`) feel translated. Prefer contractions ("you're", "let's") sparingly in dialog body copy.
- **Terminology:** "puzzle" vs. "game" used interchangeably. Standardize: **puzzle** = the board you solve; **game** = a session/run. E.g., `stats.empty` should say "puzzles", `home.newGame.warning.title` ("Game in Progress") is fine.
- **Punctuation:** mid-dot `·` in `result.grade.*` is unusual on English mobile UI — prefer commas or em dash.

## 6. No code changes

Review only — no edits applied to `app_strings.dart`. Recommend batching P0 + casing sweep (P1 #1–6) into a single l10n PR; defer P1 #7–10 to a copy-polish pass.
