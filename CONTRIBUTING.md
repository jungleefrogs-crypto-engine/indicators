# Contributing

## Adding or changing a script

1. Read [docs/STYLE_GUIDE.md](docs/STYLE_GUIDE.md) — header format, section
   order, naming, and input-group conventions apply to every file.
2. Start new scripts from a template in [examples/](examples/) rather than
   from scratch, so the header and section layout match automatically:
   - `minimal-indicator-template.pine` for indicators
   - `minimal-strategy-template.pine` for strategies
   - `minimal-library-template.pine` for libraries
3. Place the file in the right folder:
   - `indicators/<category>/` — pick an existing category
     (`trend`, `momentum`, `volatility`, `volume`, `market-structure`) or
     propose a new one if the script doesn't fit any of them.
   - `strategies/` for anything using `strategy()`.
   - `libraries/` for reusable `export`ed functions.
4. Bump the `Version:` header per [semver](https://semver.org/):
   - **patch** — bug fixes, no behavior change to inputs/outputs.
   - **minor** — new inputs, plots, or alerts, backward compatible.
   - **major** — renamed/removed inputs, changed plot semantics, anything
     that would break a chart already using the script.
5. Add an entry to [CHANGELOG.md](CHANGELOG.md) under `[Unreleased]`.
6. Run the style checks before opening a PR:

   ```sh
   ./scripts/validate-pine.sh
   ```

7. Paste the script into TradingView's Pine Editor and confirm it compiles
   with no errors, the inputs behave as expected, and any `alertcondition`s
   fire correctly.

## Pull requests

- Keep PRs scoped to one script (or one focused set of related changes).
- Fill in the PR template checklist.
- Squash fixups locally where reasonable — one script's history should be
  easy to skim in `git log`.

## Known gaps

`indicators/JungleeFrogs/TRAP-ATM-MTF-ADX/JungleeFrogs_OrderBlock_Detector_Advanced_MACD_Predictor.pine`
predates the style guide and hasn't been migrated to its header/naming/input
conventions yet. If you're touching that file, migrating it to match
`docs/STYLE_GUIDE.md` (in a dedicated PR, separate from any logic change) is
welcome — see the note in `README.md`.
