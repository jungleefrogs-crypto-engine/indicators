# Changelog

All notable changes to this project are documented here. Format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Each script keeps
its own semver `Version:` in its header (see `docs/STYLE_GUIDE.md`); this
file records what changed and when, file by file.

## [Unreleased]

### Added

- `indicators/JungleeFrogs/SMC-EDGE-SYSTEM/JungleeFrogs_Smart_Money_Edge_System.pine`:
  fixed the ACTION banner still showing red text on the neutral gray
  background for "PREPARE SELL" - `actionColor` treated "SELL NOW" and
  "PREPARE SELL" as the same red case, but `actionBg` only special-cased
  "SELL NOW" for the yellow background, so "PREPARE SELL" fell through
  to gray. Audited every other cell across the Dashboard, Screener, and
  Signal Read tables (all red-text branches already paired correctly
  with `colRedTextCellBg`, either directly or via `f_row_bg()`) - this
  was the only gap.

- `indicators/JungleeFrogs/SMC-EDGE-SYSTEM/JungleeFrogs_Smart_Money_Edge_System.pine`:
  moved the Demand/Supply zone info labels (STR/VOL/WIDTH/UNREALIZED)
  off the current bar - they were anchored at `bar_index`, overlapping
  the TP/SL/Entry labels and price scale that live in that same space.
  Two more rounds after that: `chart.right_visible_bar_time` (the first
  fix) turned out to still not be enough, because on a normal live
  chart the latest candle sits close to the right edge with only a
  small margin - the "visible space to the right of price" it was
  computing from is usually narrow, not the large gap that approach
  assumed. Replaced it with what the user actually specified: labels
  now sit a multiple of the zone's OWN width past its right boundary
  ("Zone Info Label Spacing (x Zone Width)", default 2.0) - self-scales
  with the actual zone size instead of depending on any chart-viewport
  assumption. Also switched `label.style_label_left` -> `label_right` so
  the label box extends further away from the zone as it grows, never
  back toward it (the previous style could let the box's own width
  creep back over the zone regardless of how far the anchor was placed).

- `indicators/JungleeFrogs/SMC-EDGE-SYSTEM/JungleeFrogs_Smart_Money_Edge_System.pine`:
  fixed PP still not marking a genuinely obvious reversal even after the
  cooldown fix - `ta.pivotlow()`/`ta.pivothigh()` require the low/high to
  be STRICTLY the most extreme bar in the window, so a flat or double-
  bottom/top (two candles sharing a similar low, common in a
  consolidation - exactly what live testing showed at the missed spot)
  can fail to register as a pivot at all, no matter how strong the EMA
  agreement is right there. Replaced with a custom, non-strict pivot
  check (`f_approx_pivot_low`/`f_approx_pivot_high`, ties still count),
  computed unconditionally per the same rule as the other history-
  referencing functions in this file. Tradeoff: a wide flat bottom
  spanning more bars than the cooldown window could still produce more
  than one PP marker for what's really one event - an acceptable cost
  next to missing the reversal entirely.

  Lowered the default "PP Cooldown (Bars)" from 10 to 5 - live testing
  showed a second, genuinely distinct reversal (with GL Cross/Golden H
  Cross/Golden L Cross/CHoCH all clustered right at it, a stronger
  signal than the first) went unmarked because it followed the first PP
  within the 10-bar cooldown window. 5 bars still blocks a pure noise
  burst (which clusters within 1-3 bars) while giving two real,
  distinct turns closer together a better chance to both register.

- `indicators/JungleeFrogs/SMC-EDGE-SYSTEM/JungleeFrogs_Smart_Money_Edge_System.pine`:
  optimized for performance and a reported chart-price mismatch. With
  `calc_on_every_tick=true` (needed for the mobile table-visibility fix
  earlier), the script was re-running every table rebuild and every
  line/label/box delete-and-recreate cycle - 16 separate
  `if barstate.islast` blocks (Dashboard, Screener, Signal Read, Zone
  Boxes, Trap Label, Buy/Sell grade label, Current Price/Best Entry/SL/
  TP lines, Predictable Target, live candle-pressure fill) - on every
  single incoming tick, not just once per bar. On a fast-moving symbol
  this is enough work that the drawn output can visibly lag behind the
  actual live price, which is the most likely explanation for "the
  TradingView price doesn't match the chart." Added a shared redraw
  throttle (`shouldRedraw`, new "Redraw Throttle (Milliseconds)" input,
  default 300ms) and replaced all 16 `barstate.islast` drawing gates
  with it - every underlying calculation, signal, and alert still
  evaluates on every tick exactly as before (unaffected - the input's
  own tooltip says so), only how often the already-correct results get
  redrawn is throttled. `autoLockBar`'s own unrelated `barstate.islast`
  check (option-symbol locking, not drawing) was left untouched.

  Fixed 16 "might not execute on every bar" compiler warnings on
  `f_reversing_up_at()`/`f_reversing_down_at()` (PP's curvature check) -
  same rule already applied to `ta.crossover()`/`ta.crossunder()`/
  `ta.barssince()` earlier: a history-referencing call inside a
  conditional expression (`ppPivotLowEvent and f_reversing_up_at(...)`)
  isn't guaranteed to execute consistently across bars. All 16
  combinations are now computed unconditionally first
  (`reversingUp9H`/`reversingDown9H`/etc.), with the pivot-event gating
  applied afterward on the already-computed booleans.

- `indicators/JungleeFrogs/SMC-EDGE-SYSTEM/JungleeFrogs_Smart_Money_Edge_System.pine`:
  fixed Best Entry Price sitting too far from the current close in
  practice - the nearest active zone edge is just whichever zone last
  formed, not necessarily a near one, and a distant zone made for a
  wide, less realistic entry that ate into the move available before TP.
  Added "Best Entry Max Distance (x ATR)" (default 1.0) - when the zone
  edge exceeds that distance from close, Best Entry falls back to a
  level exactly that many ATRs from price instead, keeping the entry
  within a comfortable, realistically-reachable range.

  Follow-up: that cap was a hard on/off switch (exact zone edge, or
  exact ATR-cap level - nothing in between), which caused a sudden jump
  right at the threshold instead of trailing smoothly. Replaced with a
  continuous clamp (`math.max`/`math.min` of the zone edge and the ATR-
  cap level) - Entry now trails toward price exactly like TP whenever
  the zone is out of comfortable range, and only locks onto the static
  zone level once price is close enough for that structure to matter.
  TP still trails unconditionally (it's defined relative to close every
  bar by design); Entry stays anchored to real zone structure rather
  than blindly tracking price, since a retest level that just followed
  price 1:1 would no longer mean anything structurally.

  Made Stop Loss an actual trailing stop, not just a fresh-each-bar
  recalculation like TP/Entry. `longSL`/`shortSL` are now backed by
  persistent state (`trailLongSL`/`trailShortSL`) that only ever
  tightens in the favorable direction (`math.max` for longs, `math.min`
  for shorts against the raw zone/ATR-based level each bar), resetting
  only when the Force Score's dominant side flips - a trailing stop only
  makes sense within one continuous directional stance. This isn't just
  a dashboard/display change: `strategy.exit()` already used
  `stop=longSL`/`stop=shortSL`, so the actual backtest exit orders now
  trail too, not only the TP/SL row and JSON webhook payload.

  Follow-up: the trailing SL had no visible line on the chart at all -
  it only ever showed as text in the Dashboard's TP/SL row and the JSON
  payload. Added a dotted "Stop Loss Line" (own settings group: show
  toggle, color, thickness) showing the current longSL/shortSL (the
  same level strategy.exit() uses) with a "STOP LOSS" label, matching
  the same on-chart-line pattern as Current Price Line and Best Entry.

  Added dotted "Take Profit Lines" the same way - TP1 (teal, first
  target) and TP2 (green, final target - the same level strategy.exit()
  actually uses as its limit), own settings group, labels on the
  opposite side of price from Entry/SL (above for a bullish bias, below
  for bearish) since that's where the actual TP levels sit.

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

  Added a "Perfect Position (PP)" vertical line marker: fires on a bar
  where a majority of the currently-visible 9/20/50/200 High+Low EMA
  lines are bending (or tending to bend) against the prevailing
  structure bias - e.g. bending up while structure is BEARISH, read as a
  cluster reversal across all 8 lines rather than any single line.
  Required majority scales with how many of the 8 lines are visible
  (`ceil(visibleCount * 5/8)` - 5 of 8 when all are shown, proportionally
  fewer if some are hidden, per spec). Draws a vertical line + "PP /
  Perfect Position / Trend Break" label at that bar (fires once per
  cluster, not on every qualifying bar). Note: Pine has no way to query
  the chart's actual rendered price-axis bounds, so the line is drawn
  tall (+/- 4x ATR beyond that bar's high/low) rather than a literal
  edge-to-edge line like a manually-drawn one - tall enough to stand
  out, bounded enough not to distort the chart's auto-scale.

  Two fixes/refinements made after live testing showed PP wasn't firing
  at an obvious reversal cluster (bottom of a decline, right where
  GH/GL Cross fired):
  - "Bending" now allows a per-line recency window ("PP Bend Recency
    Window (Bars)" input, default 6), instead of requiring the exact
    same bar for every line. A 9-period and a 200-period EMA never turn
    on the same bar - the 200 is heavily lagged and confirms a reversal
    many bars after the fast EMAs already have - so requiring an exact
    single-bar match across all 8 was effectively unreachable in
    practice. `ta.barssince()` is computed unconditionally for all 16
    up/down combinations (same rule already learned from the
    ta.crossover()/ta.crossunder() fix earlier - calling it only inside
    a conditional branch corrupts its state).
  - Each line now also counts as "bending" if it's decelerating (this
    bar's slope is smaller in magnitude than the prior bar's, still
    moving with the trend but slowing toward a turn) - a leading signal
    alongside the already-flipped one, so PP can mark the width of a
    real reversal cluster rather than only its exact pivot bars.

  A third fix after live testing showed PP firing at a later local top
  instead of the actual bottom of the decline: direction was gated on
  `structureBias`, but that only flips via a confirmed CHoCH, which
  happens well after price has already broken the prior swing high -
  by which point the real EMA-cluster bottom (and the bend agreement
  around it) is in the past. Removed that dependency; direction (up-
  reversal vs down-reversal) is now judged purely from which way the
  majority of the 8 lines are currently bending, tracked independently
  (`ppUpCount`/`ppDownCount` against the same scaled threshold). The
  label/line now reads "PP BUY" or "PP SELL" accordingly and is
  positioned below the bar for a bottom reversal, above for a top one.

  A fourth revision replaced the single-bar slope/deceleration checks
  entirely with a smoothed window comparison (`f_reversing_up`/
  `f_reversing_down`: net move over the last N bars vs. net move over
  the N bars before that, N = the renamed "PP Curvature Window (Bars)"
  input) - EMAs jitter bar to bar even mid-trend, so a strict 1-bar-vs-
  1-bar slope comparison was too noisy to reliably land on the actual
  visual turning point. This also removed the `ta.barssince()` calls
  entirely (no longer needed), simplifying the whole block.

  A fifth tuning pass after live testing showed PP now firing correctly
  but ~4 candles later than where the EMAs visibly started bending:
  halved the default "PP Curvature Window" from 6 to 3 bars (a shorter
  window inherently detects the turn sooner, at the cost of some noise
  resistance), and relaxed the deceleration threshold in
  `f_reversing_up`/`f_reversing_down` from requiring the recent move to
  have shrunk to less than half the prior move (0.5x) to just noticeably
  smaller (0.75x) - so a line counts as reversing earlier in its bend,
  not only once well into it. Both are adjustable in Settings if this
  still isn't quite right for a given chart/timeframe.

  Removed the "PP BUY"/"PP SELL" prefix from the PP label - it now just
  reads "Perfect Position / Trend Break". `perfectPositionIsUp` still
  drives label placement (below the bar for an up-reversal, above for a
  down-reversal), just not the text anymore.

  A sixth tuning pass, still ~2 candles later than the true bend start:
  default "PP Curvature Window" lowered to 2 (its practical floor - a
  1-bar window would reintroduce the original single-bar noise problem),
  and the deceleration threshold in `f_reversing_up`/`f_reversing_down`
  relaxed again, 0.75x -> 0.9x. Flagged in the input's tooltip that this
  is now at the responsiveness ceiling for this detection method - any
  further "earlier" push from here trades directly against false-
  positive resistance, so the next lever if still late is the required-
  agreement side (how many of the 8 lines must agree), not the window.

  A seventh pass, after live testing showed the window=2/0.9x settings
  had overcorrected - PP was now firing on ordinary EMA jitter rather
  than genuine reversal clusters, drawing many overlapping markers
  through a single trend. Walked the two detection knobs back to a
  middle ground (window 2 -> 4, deceleration threshold 0.9x -> 0.7x),
  and added the actual fix for the overlap problem: a cooldown ("PP
  Cooldown (Bars)", default 10, same proven pattern as this file's
  existing Buy/Sell signal cooldown) - `lastPPBar` tracks the bar of the
  last marker, and a new candidate is suppressed until enough bars have
  passed. This caps the noise regardless of how the detection knobs are
  tuned, which the window/threshold tuning alone could not do.

  An eighth and more fundamental redesign: PP is now anchored to a
  confirmed swing pivot (the same `ta.pivotlow()`/`ta.pivothigh()` this
  file already uses for market structure) instead of a free-floating
  EMA-curvature threshold crossing. A pivot IS, by definition, the local
  price extreme - live testing kept showing PP land near but not exactly
  on the real turning point because a pure multi-EMA-curvature blend has
  no inherent anchor to "this specific bar is the bottom/top," only to
  "enough lines have curled by now." PP now fires only when a confirmed
  pivot low/high coincides with a majority of the visible EMA lines
  curling the matching direction, checked at the pivot bar itself
  (`structRightBars` back from the confirmation bar) using the existing
  window-curvature check. The marker is drawn at that same historical
  pivot bar position (`bar_index - structRightBars`), matching the
  convention this file already uses for swing labels, instead of at the
  later confirmation bar.

  A ninth fix: PP shared the main "Structure Pivot Left/Right Bars"
  (default 5/5) with the BOS/CHoCH structure engine, which is
  deliberately coarse to avoid noise in major structure calls - a
  smaller, quicker local dip/top (exactly the kind PP is meant to catch)
  often isn't a large enough swing to register as a pivot at that
  window, so PP had no chance of firing there regardless of EMA
  agreement. Gave PP its own independent, smaller-by-default pivot
  window ("PP Pivot Left/Right Bars", default 3) via its own
  `ta.pivotlow()`/`ta.pivothigh()` calls, decoupled from the structure
  engine entirely.

  Added a "Momentum" row to the Dashboard (and its explanation on the
  Signal Read table) - `ta.mom(close, momLen)` (new "Momentum Length"
  input, default 10, in the Trend Strength & Indicator Settings group),
  runs directly on the chart's own series with no `request.security()`
  involved, so it's inherently tied to whatever timeframe is currently
  selected. Shows the raw price-change value with a green up arrow when
  positive, red down arrow (yellow background, matching the rest of the
  file's red-text convention) when negative. Both Dashboard and Signal
  Read table row counts bumped from 15 to 16 to fit the new row.

  Added a "Current Price Line" - a dotted, bold, dark reference line at
  the current close extending right ("Show Current Price Line", own
  color/thickness inputs). TradingView's own built-in last-price line
  can't be restyled from a script (that's a chart-level Symbol setting,
  not scriptable), so this is a separate script-drawn line for that.

  Added a "Best Entry Price" line + label - the nearest active zone edge
  in the direction the Market Force Score favors (top of an active
  Demand zone for a buy, bottom of an active Supply zone for a sell - a
  retest entry, not a chase), falling back to the B/S Trigger breakout
  level when there's no active zone on that side yet. This is distinct
  from the existing TP/SL row and Predictable Target box, which only
  showed where price might exit/go, not where to get in.

  Fixed all 4 EMA cross pairs (8 labels total) being invisible by
  default: they were gated behind Clean Chart Mode (default on), same as
  the original Golden/Death H pair, but that made a feature explicitly
  asked for look broken with no on-chart explanation. Removed the Clean
  Chart Mode gate from all of them - they now stay visible the same way
  CHoCH already does (a meaningful, infrequent signal, not routine
  noise), regardless of Clean Chart Mode.

  Added the 3 missing EMA crossover pairs (the 50H/200H Golden/Death
  Cross already existed) - EMA9H x EMA20H fires "GH Cross"/"DH Cross",
  EMA9L x EMA20L fires "GL Cross"/"DL Cross", EMA50L x EMA200L fires
  "GOLDEN L Cross"/"DEATH L Cross", and the original 50H/200H pair is
  relabeled "GOLDEN H Cross"/"DEATH H Cross" to distinguish it from the
  new L pair. All 4 pairs share the existing Golden/Death Cross color
  inputs and are gated behind Clean Chart Mode like the original pair -
  the fast 9/20 crosses fire often enough that they'd otherwise clutter
  the default view.

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
