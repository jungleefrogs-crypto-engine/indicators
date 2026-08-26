# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Each script keeps
its own semver `Version:` in its header (see `docs/STYLE_GUIDE.md`); this
file records what changed and when, file by file.

## [Unreleased]

### Added

- `indicators/JungleeFrogs/EMA-HL-PRESSURE-MATRIX/JungleeFrogs_EMA_HighLow_Pressure_Matrix.pine`
  (new indicator, 1.0.0): companion to the Order Block indicator above.
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
