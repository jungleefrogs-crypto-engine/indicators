# Pine Script Toolkit

A collection of TradingView Pine Script (v6) indicators, strategies, and a
shared utility library, organized and documented to a consistent standard.

## Requirements

- A TradingView account (free tier is enough) with access to the Pine
  Editor.
- Pine Script `v6` — every script in this repo declares `//@version=6`.

## Repository structure

```
pine-script-toolkit/
├── docs/
│   └── STYLE_GUIDE.md          # Conventions every script follows
├── examples/                   # Starter templates — copy, don't edit in place
│   ├── minimal-indicator-template.pine
│   ├── minimal-strategy-template.pine
│   └── minimal-library-template.pine
├── indicators/
│   ├── market-structure/       # swing-structure-mapper.pine
│   ├── momentum/                # momentum-oscillator-pro.pine
│   ├── trend/                   # trend-strength-suite.pine
│   ├── volatility/              # adaptive-volatility-bands.pine
│   ├── volume/                  # volume-flow-meter.pine
│   └── JungleeFrogs/...         # imported, not yet style-guide compliant (see below)
├── libraries/
│   └── lib-core-utils.pine      # CoreUtils — shared helper functions
├── strategies/
│   └── ema-trend-cross-strategy.pine
├── scripts/
│   └── validate-pine.sh         # Style-guide checks, also run in CI
├── CHANGELOG.md
├── CONTRIBUTING.md
└── LICENSE                      # MPL-2.0
```

## Using an indicator or strategy

1. Open the `.pine` file for the script you want.
2. In TradingView, open the **Pine Editor** tab, create a new blank script,
   and paste the file's contents in.
3. Click **Add to Chart**. Adjust inputs from the indicator/strategy
   settings dialog — every input has a label and, where useful, a tooltip.

## Using the shared library

[`libraries/lib-core-utils.pine`](libraries/lib-core-utils.pine) (`CoreUtils`)
holds helpers reused across the toolkit: safe division, oscillator
normalization, adaptive ATR bands, and simple engulfing-pattern detection.

To use it from your own scripts:

1. Paste `lib-core-utils.pine` into the Pine Editor and **Publish** it
   (can be a private/invite-only publish) under your TradingView username.
2. In any other script, import it:

   ```pine
   import <your-tradingview-username>/CoreUtils/1 as core

   safeRatio = core.f_safeDiv(a, b)
   ```

   The trailing `/1` is the published library's version number, shown on
   its TradingView publish page — bump it there each time you republish a
   breaking change, matching the `Version:` header in the source.

## What's in the toolkit

| Script | Type | Description |
| --- | --- | --- |
| [`indicators/trend/trend-strength-suite.pine`](indicators/trend/trend-strength-suite.pine) | Indicator | Three-EMA trend structure with an ADX-based strength read-out and dashboard. |
| [`indicators/momentum/momentum-oscillator-pro.pine`](indicators/momentum/momentum-oscillator-pro.pine) | Indicator | Blended RSI/Stochastic momentum oscillator with signal line and zones. |
| [`indicators/volatility/adaptive-volatility-bands.pine`](indicators/volatility/adaptive-volatility-bands.pine) | Indicator | ATR-based bands that widen automatically as relative volatility rises. |
| [`indicators/volume/volume-flow-meter.pine`](indicators/volume/volume-flow-meter.pine) | Indicator | Close-position-based buy/sell volume flow with relative-volume spikes. |
| [`indicators/market-structure/swing-structure-mapper.pine`](indicators/market-structure/swing-structure-mapper.pine) | Indicator | Labels HH/LH/HL/LL swing points and flags breaks of structure. |
| [`strategies/ema-trend-cross-strategy.pine`](strategies/ema-trend-cross-strategy.pine) | Strategy | EMA cross entries filtered by a baseline trend EMA, with ATR stop/take-profit. |
| [`libraries/lib-core-utils.pine`](libraries/lib-core-utils.pine) | Library | Shared helper functions used across the scripts above. |

## Conventions

Every script in this repo (aside from the known gap below) follows
[docs/STYLE_GUIDE.md](docs/STYLE_GUIDE.md): a standard header, a fixed
section order (Inputs → Calculations → Orders/Plots → Alerts), kebab-case
filenames, camelCase variables, and `f_`-prefixed exported library
functions. Start new scripts from a template in
[examples/](examples/) rather than from scratch.

[`scripts/validate-pine.sh`](scripts/validate-pine.sh) checks new/changed
scripts against these conventions and runs automatically in CI
(`.github/workflows/validate.yml`) on every push and pull request. Run it
locally before opening a PR:

```sh
./scripts/validate-pine.sh
```

See [CONTRIBUTING.md](CONTRIBUTING.md) for the full workflow, and
[CHANGELOG.md](CHANGELOG.md) for what's changed and when.

## Known gaps

[`indicators/JungleeFrogs/TRAP-ATM-MTF-ADX/JungleeFrogs_OrderBlock_Detector_Advanced_MACD_Predictor.pine`](indicators/JungleeFrogs/TRAP-ATM-MTF-ADX/JungleeFrogs_OrderBlock_Detector_Advanced_MACD_Predictor.pine)
is an imported indicator that predates the style guide. It works, but its
header, input-group naming, and file name don't yet follow
`docs/STYLE_GUIDE.md`, so it's excluded from `validate-pine.sh`. Migrating
it (as a dedicated PR, separate from any logic change) is welcome — see
`CONTRIBUTING.md`.

## License

[MPL-2.0](LICENSE) — see the license header in each file.
