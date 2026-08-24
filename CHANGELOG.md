# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Each script keeps
its own semver `Version:` in its header (see `docs/STYLE_GUIDE.md`); this
file records what changed and when, file by file.

## [Unreleased]

### Added

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
