# Pine Script Style Guide

Conventions followed by every script in this project. Match these when adding
new scripts so the whole toolkit reads consistently.

## File header

Every script starts with:

```pine
// This source code is subject to the terms of the Mozilla Public License 2.0 at https://mozilla.org/MPL/2.0/
// © <your-tradingview-username>

// ============================================================================
// Title:        <Name>
// Description:  <What it measures/shows, in one or two sentences>
// Version:      <semver, e.g. 1.0.0>
// ============================================================================

//@version=6
indicator("...", shorttitle = "...", overlay = true/false)
```

- `//@version=6` is always the last comment line directly above the
  `indicator()` / `strategy()` / `library()` declaration.
- Version numbers follow [semver](https://semver.org/): bump patch for
  fixes, minor for new inputs/features, major for breaking changes to
  inputs or plot outputs. Log every bump in `CHANGELOG.md`.

### Library header

Libraries use TradingView's own doc-comment annotations instead of the
`Title:`/`Description:` banner, since `@description` and `@function` are
what TradingView renders as the published library's documentation:

```pine
// This source code is subject to the terms of the Mozilla Public License 2.0 at https://mozilla.org/MPL/2.0/
// © <your-tradingview-username>
// Version: <semver>

//@version=6

// @description <What this library provides and why scripts should import it.>
library("<Name>", overlay = true/false)

// @function <One sentence describing what the function does.>
// @param <name> <What this parameter is.>
// @returns <What is returned.>
export f_myFunction(...) => ...
```

Every exported function gets its own `@function`/`@param`/`@returns`
block directly above it. The `// Version:` comment line is still required
— it's what `CHANGELOG.md` entries reference, since library versioning
isn't otherwise visible in the source.

## File organization

Every script is split into the same labeled sections, in this order, using
`// ---- Section ----` comments:

1. **Inputs** — grouped with `input.*(..., group = GRP_X)`. Group name
   constants are declared with `var string GRP_X = "..."` at the top of the
   section so the group label is defined once.
2. **Calculations** — all `ta.*`, `math.*`, and derived series.
3. **Plots** — `plot()`, `plotshape()`, `fill()`, `bgcolor()`, `table.*`.
4. **Alerts** — `alertcondition()` calls, one per distinct signal, with a
   descriptive `title` and a `message` that includes `{{ticker}}` and
   `{{interval}}`.

## Naming

- **Files:** kebab-case, `.pine` extension — e.g. `trend-strength-suite.pine`.
- **Variables/functions:** camelCase (`fastEma`, `f_safeDiv`).
- **Exported library functions:** prefixed `f_` (e.g. `f_adaptiveBands`) so
  call sites read clearly as function calls.
- **Input group labels:** short Title Case strings shared as `GRP_*`
  constants, not re-typed at each `input.*` call.

## Coding conventions

- Prefer built-ins (`ta.ema`, `ta.atr`, `ta.dmi`, `ta.pivothigh`, ...) over
  hand-rolled math — they're optimized and battle-tested.
- Never use `security()`/`request.security()` without considering repainting;
  if a script needs a higher timeframe, document the repaint behavior in its
  header and default to `lookahead = barmerge.lookahead_off`.
- Use `var` only for state that must persist across bars (running totals,
  last pivot, etc.), not as a substitute for a plain calculation.
- Guard every division with `f_safeDiv` (from `libraries/lib-core-utils.pine`)
  or an explicit `!= 0` check — never divide by a series value directly.
- Colors: use `color.new(color.<name>, transparency)` rather than hex
  literals, so themes stay consistent and transparency is explicit.
- Keep alert messages actionable: include what happened, the ticker, and the
  interval, so a fired alert is understandable without opening the chart.

## Inputs

- Every user-facing number gets a sensible `minval` (and `maxval` where a
  range makes sense) and a short, plain-English label — not the variable
  name.
- Add a `tooltip` when the input's effect isn't obvious from its label alone.
- Order inputs within a group from "most commonly changed" to "advanced."
