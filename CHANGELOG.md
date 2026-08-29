# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Each script keeps
its own semver `Version:` in its header (see `docs/STYLE_GUIDE.md`); this
file records what changed and when, file by file.

## [Unreleased]

### Added

- `indicators/JungleeFrogs/TRAP-ATM-MTF-ADX/JungleeFrogs_OrderBlock_Detector_Advanced_MACD_Predictor.pine`:
  merged the PRESSURE panel's separate "Bull Score" / "Bear Score" rows
  into one "Bull/Bear Score" row reading "X/100 or Y/100", colored by
  whichever side currently leads (lime/red/white). Removed the now-unused
  `showRowBearScore` row-visibility toggle; `showRowBullScore` (relabeled
  "PRESSURE: Bull/Bear Score") now controls the single merged row.

- `indicators/JungleeFrogs/SMC-EDGE-SYSTEM/JungleeFrogs_Smart_Money_Edge_System.pine`
  (new, 1.0.0): a `strategy()` (not `indicator()`) so TradingView's Strategy
  Tester works natively - no separate "backtest mode" toggle needed. Buy/Sell
  signals reuse the confluence + multi-bar-confirmation EMA9 slope logic
  proven in the EMA High/Low Pressure Matrix indicator, now gated by Entry
  Grade and Trap Risk. Combines, in one system: Order Blocks (Demand/Supply
  zones showing STR, Volume, OI, and a Volatility/ATR-width ratio, each
  fading to (STALE) instead of vanishing once inactive - same fix as the
  EMA-HL indicator), Liquidity Sweep/grab detection, Retest confirmation,
  BOS/CHoCH market structure (Change of Character = the first break against
  the prevailing HH/HL/LH/LL bias, which is what flips it), a 2-timeframe
  MTF alignment dashboard, an ADX/DMI Trend Strength filter, Trap/fake-
  breakout warnings, an Avoid-Chase filter, an ATR-based auto TP1/TP2/SL/
  Invalidation engine, a 0-100 Market Force Score, an A+/A/B/AVOID Entry
  Grade, a session filter (Opening/Mid-Day/Closing), a fixed 10-symbol
  screener table, and JSON-formatted alert/webhook payloads (via
  `alert_message` on `strategy.entry`/`strategy.exit`, plus plain
  `alert()` calls). EMA 9/20/50/200 High+Low and VWAP are each independently
  configurable (show/color/thickness), plus one shared Plot Style dropdown
  (Pine's `plot()` has no dashed/dotted style, only Line/Step Line/Circles/
  Cross). Six filters (Trap detection, Liquidity sweep, Advance entry, MTF
  alignment, Trigger/invalidation, Avoid-chase) are independently toggleable,
  each with its own dashboard row visibility control.

  Three items from the spec are flagged in the file's own header rather than
  implemented as code, because Pine/TradingView cannot do them at all:
  - The screener is a fixed 10 symbols, not "many" - Pine hard-caps every
    script at 40 total `request.security()` calls, shared with the MTF
    dashboard and options/OI machinery.
  - "Backtest mode" IS this script (see above) - Pine has no way for one
    script to be both an `indicator()` and a `strategy()`.
  - Invite-only/paid access cannot be coded in Pine at all - there is no
    license-check or user-identity API in the language. It's a TradingView
    website feature (Manage Access, after publishing), unrelated to this
    file's contents - no in-script "access toggle" was built, since it
    would provide zero real protection and be actively misleading.

  Compile-error fix found while pasting the script into TradingView: the
  Buy/Sell `plotshape()` labels tried to build their text by concatenating
  `entryGradeText` onto "BUY"/"SELL" - `plotshape()`'s `text=` must be a
  const string and cannot be built from a series value at all (unlike
  `label.new()`, which has no such restriction). Fixed by keeping the
  plotshape's text as the fixed literal "BUY"/"SELL" (so it still persists
  automatically across all of history, matching the other two scripts'
  proven Safe Entry/Exit pattern), and adding a separate `label.new()` next
  to it that shows the exact grade (dynamic text is fine there) for the
  latest signal only.

  Added "Clean Chart Mode" (default on) after testing showed the raw BOS
  triangles + HH/HL/LH/LL swing labels + Golden/Death Cross text buried the
  actionable output (Buy/Sell labels, zones, dashboard) under structure
  noise on a busy chart. When on, it forces off BOS triangles, swing
  labels, and cross-label text regardless of their own settings - CHoCH
  stays visible even in Clean Mode, since it's the rare, meaningful
  reversal signal rather than routine noise. Turn it off for the full
  raw-structure view.

  Fixed "Dashboard Font Size" = Tiny making the table effectively
  disappear: the value column dropped all the way to `size.tiny`, which
  TradingView renders too small to read at normal zoom - easy to mistake
  for the table not loading at all. Removed "Tiny" from the dropdown
  (`options=["Small", "Normal", "Large", "Huge"]`); "Small" (the default)
  is now the floor and was already confirmed visible.

  Defensively reordered the on-`barstate.islast` drawing code: Main
  Dashboard and Multi-Symbol Screener table sections now execute before
  Trap Warning Label / Order Block Zone Boxes / Branding Label, so the two
  highest-value elements render regardless of anything unresolved further
  down that chain. Pure reorder, no logic changes - verified line-for-line
  (same 1010 lines, identical sorted content, no drops/duplicates at the
  three splice points).

  Added a third on-chart table, "Signal Read Legend" ("Show Signal Read
  Legend Table", default on, own "Signal Read Position" dropdown) - a
  plain-English "what does this row mean" line for every Dashboard row
  currently visible, in the same order, driven by the same per-row
  visibility toggles so the two tables never drift out of sync.

  Added, then removed, a Settings-checkbox "fold to header only" control
  for all three tables: Pine has no way to add a clickable fold/unfold
  control on the chart itself (no in-script click handling on drawings at
  all), and a Settings-only checkbox just looked like a broken button once
  toggled on with no visible way back. Each table's own "Show ..." toggle,
  plus every Dashboard row's individual show/hide checkbox, is the
  supported way to control what's visible.

  Fixed a stale Demand/Supply zone box silently losing its "WIDTH: #.##x
  ATR" line: `demandVolatilityRatio`/`supplyVolatilityRatio` were gated on
  `demandActive`/`supplyActive`, so once a zone aged into "(STALE)" the
  ratio evaluated to `na` and the WIDTH line vanished from the label -
  while STR, VOL, and UNREALIZED (all computed from the zone's stored
  snapshot, not its live active state) kept showing, making the label look
  inconsistently incomplete. The ratio now only checks that the zone's
  high/low/ATR are known, matching how the rest of the label already
  behaves for stale zones.

  Removed the "🐸 JungleeFrogs" on-chart branding label and its section -
  purely decorative, carried no data, and the user asked for it gone since
  it added no analytical value. `colBrand` input stays; it still colors
  the Screener/Signal Read table header rows.

  Added DI+ and DI- columns to the Multi-Symbol Screener table (now 6
  columns: SYMBOL/BIAS/RSI/ADX/DI+/DI-), sourced from the same `ta.dmi()`
  call `f_scan()` already ran per symbol (previously computed and
  discarded) - no added `request.security()` calls. Every numeric column
  (RSI, ADX, DI+, DI-) now carries its own directional arrow: RSI vs 50,
  ADX vs the existing "ADX Trend Level" input combined with which DI is
  dominant (mirrors the Main Dashboard's own Trend row), and DI+/DI- each
  arrow toward whichever of the pair is currently higher. Each arrow's
  cell is colored to match - green text for ▲, red text for ▼ (white for
  → ), with the same red-text/yellow-background convention already used
  everywhere else in the table for the red case.

  Added a PRICE column (7th, after DI-) to the Screener table - the
  scanned symbol's current close, which `f_scan()` already fetched via
  `request.security()` for internal bias calculation but never displayed.

  Split the Dashboard's single "Trigger" row (which only ever showed
  whichever side matched the current Entry Grade) into two always-visible
  rows: "B Trigger" (buy-side price level, lime text) and "S Trigger"
  (sell-side, red text) - both levels are now visible together instead of
  one being hidden. Mirrored the same split on the Signal Read legend
  table. Both tables' row counts bumped from 14 to 15 to fit the extra
  row; the "Trigger / Invalidation" row-visibility toggle is renamed
  "B Trigger / S Trigger" and now shows/hides both rows together.

  Fixed the new S Trigger row's value cell (red text) missing the
  yellow background every other red-text cell in this file already gets
  via `colRedTextCellBg`. While checking for other gaps, also found and
  fixed a real pre-existing bug in the ACTION banner: `actionBg` was solid
  red for both AVOID and SELL NOW, the same cases where `actionColor` is
  also red - red text on a red background, effectively illegible. Both
  now use `colRedTextCellBg` (yellow) instead.

  Added Pivot/R1-R3/S1-S3 levels (selectable timeframe, non-repainting -
  same proven `request.security(..., lookahead=barmerge.lookahead_on)` on
  the prior confirmed HTF bar technique as the EMA High/Low Pressure
  Matrix indicator), plotted gold with `plot.style_linebr`. This file's
  own PLOTS section comment used to say "Pivot-free (this system uses
  zones, not pivots)" - updated now that it has them.

  Added a "Predictable Target (Next Bar)" range box: current price +/- 1
  ATR (this chart's own typical single-bar range) in whichever direction
  the Market Force Score currently favors, drawn as a shaded box spanning
  to the next bar with a label reading "NEXT <N> MIN TARGET" (N computed
  from `timeframe.in_seconds(timeframe.period)`, so it always matches the
  chart's own resolution) plus the projected price and % move. Note: Pine
  cannot script TradingView's manual "Price Range" drawing tool - there is
  no API for a script to create one, it is a mouse-drawn UI-only tool -
  so this is a script-drawn box+label built to communicate the same
  information (a shaded target zone with the price/percent delta
  labeled), not a literal use of that tool. It is also explicitly a
  volatility-based projection, not a guaranteed prediction; the tooltip
  says so.

  Re-added "Tiny" to the Dashboard Font Size dropdown (one step smaller
  than "Small"), at the same size mapping it had before it was pulled
  earlier this session over a report of the table "vanishing" on that
  setting. That report predates the `calc_on_every_tick` fix above, which
  is a much more likely explanation for a table intermittently not
  rendering than the font size itself - `size.tiny` is a normal, valid
  Pine table size. Tooltip now just notes Tiny can be hard to read and to
  fall back to Small if so.

  Fixed the Dashboard/Screener/Signal Read tables not appearing at all on
  the native TradingView mobile app (desktop/web worked fine) - the real
  cause, found from the Pine Editor's own compile warnings: with
  `calc_on_every_tick=false`, `barstate.islast` is not reliable on an
  unconfirmed realtime bar, and every table/label/box in this file draws
  inside `if barstate.islast`. Changed the `strategy()` declaration to
  `calc_on_every_tick=true`. This does not change trade-entry timing -
  `buySignalRaw`/`sellSignalRaw` were already separately gated on
  `barstate.isconfirmed`, so entries/exits still only fire on confirmed
  bar closes; only the visual drawing code now refreshes reliably.

  Fixed a real correctness bug the same warning pass surfaced: the
  BOS/CHoCH `ta.crossover()`/`ta.crossunder()` calls ran inside a
  conditional (`not na(lastSwingHigh) and ta.crossover(...)`) - these
  functions track bar-to-bar state and must run unconditionally on every
  bar, or their result can be wrong once the condition starts evaluating
  true again. Split into an unconditional `structCrossUp`/`structCrossDown`
  assignment, with the `not na(...)` check applied afterward.

  Removed 4 `alertcondition()` calls the same warning pass flagged as
  dead code - `alertcondition()` has no effect inside `strategy()`
  scripts (indicator()-only). The equivalent `alert()` calls just above
  them already cover all 4 cases and work correctly in strategies.

  Added the BUY(Blue)/SELL(Yellow) candle pressure fill, ported from the
  EMA High/Low Pressure Matrix indicator's proven implementation (new
  "Candle Buy/Sell Pressure" input group: show toggle, segment width,
  visible history in bars, buy/sell colors). A 6-vote blend (trend, MACD,
  EMA stack, VWAP, volume, candle body/close-position) sets the blue/
  yellow split filled inside each candle's own high-low range. Added the
  one vote that didn't already exist here (`bodyBull`/`bodyBear`, from
  body-to-range ratio and close position within the bar) - every other
  vote (`trendBull`, `macdBull`, `emaBull`, `vwapBull`, `volBull`) was
  already computed elsewhere in this file and reused as-is.

  Fixed a stale Demand/Supply zone box drawing in a structurally
  contradictory position - e.g. a stale (invalidated) Demand/floor zone
  left sitting above the currently active Supply/ceiling zone, which
  reads as nonsensical since a floor can never legitimately be above a
  ceiling. Each zone was drawn independently with no awareness of the
  other, so once one went stale nothing stopped it from being shown on
  the wrong side of the live one. A stale zone is now suppressed (not
  drawn) whenever it would sit on the wrong side of the currently active
  opposite zone; the active zone always keeps showing.

- `indicators/JungleeFrogs/EMA-HL-PRESSURE-MATRIX/JungleeFrogs_EMA_HighLow_Pressure_Matrix.pine`
  (1.1.0): mobile usability + critical zone visibility.
  - Table compression for small screens: a new "Compact Table Labels"
    input (default on) shortens every row name (e.g. "Volume Pressure" ->
    "Volume", "PCR / Option Skew" -> "PCR"), and the default "Table Font
    Size" changed from Normal to Small - combined, the 27-row table takes
    noticeably less screen space, especially on a phone. Full labels and
    larger sizes are still one setting away.
  - Renamed "Safe Entry"/"Safe Exit" to "Safe Buy Entry"/"Safe Sell Entry"
    throughout (bubble text, alerts, alertcondition names, input labels) -
    reframes both as entry points for opposite directions (long vs short)
    rather than entry-vs-exit-of-a-long. The EARLY variants follow the
    same naming ("EARLY Safe Buy Entry"/"EARLY Safe Sell Entry"). No
    change to the underlying trigger logic, only the labels.
  - Added "critical" Demand/Supply zone boxes (green/red, colors
    configurable) for the single most recent zone of each kind - the same
    one driving the STR Strength/Price Location/Liquidity Sweep/Breakout/
    Retest table rows when active - each labeled with its STR score and a
    new "Unrealized" count: how many prior zones of that kind formed and
    were replaced by a fresh one without price ever coming back to test
    them. "Show Critical Demand/Supply Zone Boxes" input, default on.
    Initially gated on the zone being "active"; fixed same-day after
    testing showed a Demand box could simply vanish once it aged past
    Order Block Life or moved too far from price (e.g. after a rally then
    reversal) while Supply kept showing - the box now always shows the
    last-formed zone of each kind, fading with a dashed border and
    "(STALE)" in the label once it's no longer active, instead of
    disappearing. Default "Demand Zone Border" color darkened from Pine's
    plain `color.green` to a dark green (`rgb(0,100,0)`) - it doubles as
    the zone label's background with white text, and the lighter green
    didn't give enough contrast to read the white text against clearly.
  - 8 fully configurable EMAs (9/20/50/200, each on High AND Low separately,
    each with its own color + line thickness input).
  - Golden/Death Cross on the 9H/20H pair and the 50H/200H pair.
  - Safe Entry / Safe Exit label bubbles, firing on an EMA9-Low slope
    reversal (entry, at the candle low) or an EMA9-High slope reversal
    (exit, at the candle high) - an early, one-candle-ahead cue.
  - BUY(blue)/SELL(yellow) pressure fill inside every candle, blended from
    6 of the table's rows (EMA/VWAP/MACD/Volume/Body/Trend).
  - A 26-row "Force / Pressure" dashboard: 22 rows computed live from
    price/volume/ADX/MACD/divergence/order-block/options data, plus 4
    manual dropdowns (News, Sector Breadth, Global Markets, Currency/Bond/
    Crude) for context no chart can auto-detect - these are honestly
    labeled as your own manual input, not an algorithmic signal. Every row
    has its own visibility checkbox (default on) and the table compacts
    around whichever are hidden; a shared font-size control; a ▲/▼ arrow
    and green/red/white verdict color per row; and red text always gets
    a yellow cell background, matching the Order Block indicator's
    conventions throughout.
  - OI Pressure, Volatility/IV, and PCR/Option Skew reuse the same
    auto ATM CE/PE + Black-Scholes IV machinery as the Order Block
    indicator, and degrade to "N/A" automatically on instruments with no
    option chain (crypto, forex, plain stocks) - same behavior everywhere.
  - Demand/Supply zone detection runs internally to power 5 of the 26 rows
    (STR Strength, Price Location, Liquidity Sweep, Breakout Pressure,
    Retest Confirmation) but, unlike the Order Block indicator, does not
    draw zone boxes/labels on the chart - this indicator's on-chart footprint
    is limited to the EMA lines, cross markers, Safe Entry/Exit bubbles, and
    the candle pressure fill.

- `indicators/JungleeFrogs/EMA-HL-PRESSURE-MATRIX/JungleeFrogs_EMA_HighLow_Pressure_Matrix.pine`:
  post-publish fixes found while pasting the script into TradingView.
  - Volume Pressure used `ta.sum()`, which doesn't exist in Pine - the
    rolling-sum function is `math.sum()`. Compile error, now fixed.
  - The neutral ("→") verdict color was `color.yellow`, which reads as a
    dull red/rust on this table's dark background - indistinguishable
    enough from real red that it looked like a missed case of "red text
    needs a yellow background." Neutral is now `color.white` for maximum
    contrast against both red and green. Pine's `table.cell` has no true
    bold parameter (same limitation noted in the Order Block indicator);
    value cells already render one size step larger than their row label
    (`tableValueSize`), which stands in for "bold" throughout. Range
    Compression's "SQUEEZE" state shows orange (a warning, not bull or
    bear) while "NORMAL" shares the same neutral white.
  - Added a plotted VWAP line, styled the same way as the 8 EMAs (own
    color + thickness input in EMA High/Low Settings) - VWAP was already
    computed for the VWAP Pressure row but was never actually plotted on
    the chart.
  - Added Pivot / R1 R2 R3 / S1 S2 S3 (selectable timeframe, default Daily),
    all gold-colored via a single "Pivot Points" input group - same
    non-repainting `lookahead_on` technique on the prior confirmed HTF
    bar's H/L/C as the Order Block indicator's pivot section.
  - Replaced the single "Show EMA 9/20/50/200 High/Low Lines" master
    toggle with 8 independent checkboxes, one per line (e.g. "Show EMA 9
    High", "Show EMA 9 Low", ... "Show EMA 200 Low") - any single EMA, or
    just its High or Low half, can now be switched off on its own. VWAP
    got its own "Show VWAP" toggle for the same reason.
  - Safe Exit fired from EMA9-High ticking down for a single bar even while
    EMA9-Low was still climbing hard - a normal one-bar pause inside an
    intact uptrend, not a rollover, which produced panic-exit-then-re-entry
    whipsaws right as the rally continued (confirmed against two separate
    real chart examples). Three combined fixes, mirrored for Safe Entry:
    1) multi-bar confirmation - the slope reversal must hold for
    `safeConfirmBars` (default 2) consecutive bars via `ta.rising`/
    `ta.falling`, not fire on the very first tick; 2) confluence - Safe
    Exit also requires EMA9-Low to not be actively rising right now
    ("Require Both EMA9 High & Low To Agree" input, default on);
    3) a minimum slope-magnitude filter (`safeMinSlopeATR`) rejecting
    sub-ATR moves over the confirmation window.
  - Added a separate "EARLY Safe Entry"/"EARLY Safe Exit" signal (smaller,
    distinctly labeled bubble; "Show EARLY Safe Entry/Exit" input, default
    on) that fires roughly one candle ahead of the confirmed signal, on
    momentum deceleration (the EMA9 side is still moving the old direction
    but each bar's move is smaller than the last) rather than a completed
    reversal. Intentionally faster and less reliable than the confirmed
    signal - kept as an additional, clearly-labeled heads-up rather than
    replacing the whipsaw-resistant confirmed one.

### Fixed

- `indicators/JungleeFrogs/TRAP-ATM-MTF-ADX/JungleeFrogs_OrderBlock_Detector_Advanced_MACD_Predictor.pine`:
  targeted fixes for signals that contradicted each other on the dashboard.
  - `f_safe_zone_score` (STR/zone strength) now caps each half of the score at
    50 before summing, so it always stays in [0, 100]. Previously it could
    exceed 100, which let it dominate the Pressure Priority blend over
    OI%/Volume%/Location/Direction, which are already 0-100.
  - Added `obMaxDistanceATR` input (default 6.0 ATR, 0 = disabled): a
    Demand/Supply zone now also deactivates once price has moved this many
    ATRs away from it, even if still inside its bar-count window.
  - Forecast box now reads "BULL/BEAR SCORE" instead of "BULL/BEAR PROB" -
    these are independent confluence checklists, not complementary
    probabilities, and were never meant to sum to 100%.
  - AMP dashboard "MTF" row relabeled "Regime TF" so it reads as a
    timeframe tag distinct from "MTF Power".
  - Added a "Consensus" row tallying how many of the 5 independent
    bull/bear engines agree, e.g. "BULL 4/5".
  - When "EXIT LONG"/"EXIT SHORT" fires while the Consensus row still agrees with
    the open side, it now reads "PARTIAL EXIT LONG"/"PARTIAL EXIT SHORT" instead -
    a momentum pause inside an intact trend is a take-partial-profit/tighten-stop
    situation, not a full-reversal instruction. A genuine trend flip (Consensus
    also turns against the position) still shows the plain "EXIT LONG/SHORT".
  - "TRAP / AVOID" (and Trade Mode's "AVOID / TRAP") now names which side the
    trap actually warns against, e.g. "TRAP / AVOID BUY" - previously it read
    as "avoid everything" even when the trap (e.g. a fake breakout) only
    invalidated one side.
  - `trapReasonText` "FAKE BUY BREAK"/"FAKE SELL BREAK" spelled out to
    "FAKE BUY BREAKOUT"/"FAKE SELL BREAKDOWN".
  - AMP-MTF "Score" row spelled out "BULL"/"BEAR" instead of "B"/"S" - the "S"
    there meant Bear while the Pressure table's own "D/S" row means
    Demand/Supply, so the same letter carried two different meanings.
  - The Pressure table's "ADV BUY/SELL WATCH" could still show green/all-clear even
    when Trap Risk had specifically flagged that exact setup as a trap (buying into
    Supply / selling into Demand) - e.g. AMP-MTF said "TRAP / AVOID BUY" while
    Pressure said "ADV BUY WATCH" for the identical signal. The Pressure header and
    Advance cell now show "TRAP / AVOID <side>" too whenever Trap Risk is specifically
    about that side, so both tables agree instead of contradicting each other.
  - That trap-vs-pressure check above only covered 2 of 4 trap reasons
    (buyIntoSupplyTrap/sellIntoDemandTrap) - a "ZONE SQUEEZE" or "BOTH STRONG"
    trap still slipped through as a green/red "ADV WATCH". Broadened to any
    active trap reason coinciding with an active Advance signal.
  - The on-chart ADV BUY/SELL pointer label was drawn before Trap Risk existed
    in the script, so it could never reflect it - it would keep pointing
    green/red at a signal the dashboard had already flagged as trapped. Moved
    it after Trap Risk is computed so it now shows the same "TRAP / AVOID
    <side>" the tables show.
  - Demand/Supply zone "VOL:" labels showed "0" on crypto pairs, where volume
    is denominated in the base asset (e.g. 0.01 BTC per candle) - `format.volume`
    is built for large share/contract counts and rounds small fractional values
    down to "0" for display. Added `f_format_vol` to show plain decimals under
    1000 instead.
  - Trigger cell reads "BUY IF PRICE > ..."/"SELL IF PRICE < ..." instead of
    the terser "BUY > .../SELL < ...".
  - AMP-MTF "Score" row now gets a yellow background when its text is red
    (Bear leading), matching the same convention used for DI-, Regime TF,
    MTF Power, and Trap Risk elsewhere in the dashboard.
  - "Regime" row relabeled "Regime (200EMA)" - it's a slow 200-period EMA
    filter, not a live directional signal, so it can legitimately still say
    BULLISH while ADX/DMI and other fast-reacting cells have already flipped
    bearish during a sharp move. That's expected behavior, not a conflict -
    the label now says so instead of looking like an equal-weight contradiction.
  - "Consensus" row now gets a yellow background when its text is red (Bear
    leading), matching the same convention as Score, DI-, Regime TF, MTF
    Power, and Trap Risk elsewhere in the dashboard.

### Added

- `indicators/JungleeFrogs/TRAP-ATM-MTF-ADX/JungleeFrogs_OrderBlock_Detector_Advanced_MACD_Predictor.pine`:
  - "Table Font Size" input (Tiny/Small/Normal/Large/Huge, default Normal):
    controls all three tables (AMP-MTF, PRESSURE, ADX/DMI) together. Row
    labels render one size step below their value cells, same relative
    sizing as before, just adjustable together instead of fixed.
  - "Dashboard Row Visibility" input group: one checkbox per row across the
    AMP-MTF table, PRESSURE table, and ADX/DMI panel (28 total), all
    defaulting to true. Unticking a row removes it entirely and the table
    compacts around the gap - rows are drawn via a running row-index counter
    per table instead of a fixed index, so hidden rows leave no blank space.
  - "Momentum" row (AMP-MTF table): Rate of Change over `momentumRocLen` bars
    (default 10), e.g. "+1.8% ▲" in green, "-0.9% ▼" in red on a yellow
    background - value and arrow always share one color/direction.
  - "CE IV" / "PE IV" rows (PRESSURE table): ATM CE/PE Implied Volatility,
    back-solved from the already-fetched option premium via a real
    Black-Scholes model (Newton-Raphson solver, `ivRiskFreeRatePct` input for
    the risk-free rate). Split into two rows, each with its own bar-over-bar
    ▲/▼ arrow and green/red color, since call and put IV can move in
    different directions (skew) - one combined cell can't show two colors.
    Shows "N/A" on instruments with no option premium data (e.g. spot crypto).
  - `emaLineWidth` input (default 3, was a fixed 2): controls the plotted
    thickness of all four EMA 9/20/50/200 lines together.
  - Added a plotted VWAP line, styled like the EMAs: its own color
    (`colVWAP`), its own thickness (`vwapLineWidth`), and its own "Show
    VWAP" visibility checkbox. VWAP was already computed and used
    internally (Probability engine, Safe Entry/Exit) but was never
    actually drawn on the chart.

- Repository scaffolding: `README.md`, `LICENSE` (MPL-2.0), `CONTRIBUTING.md`,
  `.gitignore`, `.gitattributes`, `.editorconfig`.
- `scripts/validate-pine.sh` and a GitHub Actions workflow that check every
  `.pine` file against `docs/STYLE_GUIDE.md` on push/PR.
- Strategy and library starter templates in `examples/`, alongside the
  existing indicator template.
- `docs/STYLE_GUIDE.md`: documented the library header format
  (`@description`/`@function` annotations plus a `Version:` comment), since
  it intentionally differs from the indicator/strategy `Title:` banner.

### Changed

- `libraries/lib-core-utils.pine`: added the missing `Version:` header
  comment (1.0.0) so the library follows the same version-tracking
  convention as every other script.

## [1.0.0] - 2026-08-24

### Added

- `libraries/lib-core-utils.pine` (CoreUtils 1.0.0) — safe division,
  oscillator normalization, adaptive volatility bands, and simple
  engulfing-pattern detection, shared across the toolkit.
- `indicators/trend/trend-strength-suite.pine` (1.0.0) — three-EMA trend
  structure with an ADX-based strength read-out and dashboard.
- `indicators/momentum/momentum-oscillator-pro.pine` (1.0.0) — blended
  RSI/Stochastic momentum oscillator with signal line and zones.
- `indicators/volatility/adaptive-volatility-bands.pine` (1.0.0) —
  ATR-based bands that widen automatically with relative volatility.
- `indicators/volume/volume-flow-meter.pine` (1.0.0) — close-position-based
  buy/sell volume flow with relative-volume spike detection.
- `indicators/market-structure/swing-structure-mapper.pine` (1.0.0) —
  HH/LH/HL/LL swing labeling with break-of-structure flags.
- `strategies/ema-trend-cross-strategy.pine` (1.0.0) — EMA cross entries
  filtered by a baseline trend EMA, with ATR-based stop/take-profit.
- `indicators/JungleeFrogs/TRAP-ATM-MTF-ADX/JungleeFrogs_OrderBlock_Detector_Advanced_MACD_Predictor.pine`
  — imported order block / MACD / ADX dashboard indicator. Predates
  `docs/STYLE_GUIDE.md` and is **not yet migrated** to its header, naming,
  or input-group conventions (tracked as a known gap — see `README.md`).
