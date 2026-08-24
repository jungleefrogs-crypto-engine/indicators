# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Each script keeps
its own semver `Version:` in its header (see `docs/STYLE_GUIDE.md`); this
file records what changed and when, file by file.

## [Unreleased]

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
