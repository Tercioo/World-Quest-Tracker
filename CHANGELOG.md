## Custom GameFont and 1.0 icon-baseline normalization

- Removed WQT's explicit LibSharedMedia font-name assignments and standardized addon text on cached font objects derived from Blizzard `GameFontNormal`.
- Added a safe refresh pass for WQT-owned frames so framework-created labels, buttons, options, tracker rows, and dynamically created widgets retain the game font.
- Standardized continent-map pins, zone-map pins, world/continent summary icons, and zone-summary icons on a 24px base with a 17px reward texture.
- Changed the continent-map icon scale control to a true multiplier, so `1.0` is neutral and matches the zone-map scale baseline.
- Corrected the continent-map icon scale slider increment to `0.05`.

## Custom Slayer's Duellum Warband reputation tooltip fix

- Added Slayer's Duellum (faction ID 2770) to the Midnight Warband reputation faction set.
- World-quest tooltips now show the one-time Warband reputation bonus line for eligible Slayer's Duellum reputation rewards.

## Custom zone-heading and transmog-position fix

- Yellow zone headings now use the underlying FontString directly and are forcibly hidden whenever the world summary is ordered by type.
- Moved the transmog collected/uncollected marker to the top-left corner of each world-quest icon, leaving the quest-type marker at top-right.

## Custom selection controls and zone-heading fix

- Bottom-right reward-type selectors now track every matching world quest, including pet battles by quest tag.
- Bottom-middle faction selectors now track every visible quest that awards reputation with the selected faction.
- Restored reliable click handling for individual quests and category selectors in the left summary.
- Yellow zone headings are now shown only while the summary is organized by zone, including immediate cleanup when changed through Options.

## Custom hotfix — world-quest type selector

- Restored mouse interaction for the pet, gold, resource, and primary-currency selectors on the map status bar.
- Raised only the four selector button frames above map and summary pins while keeping the full-map anchor frame mouse-transparent.
- Made selector tracking resilient to lazy summary rebuilds by falling back to visible world-map and summary widgets when the type cache is temporarily incomplete.
- Corrected pet-battle selection to match the world-quest tag instead of the reward bucket.

## Custom production merge — Midnight 12.0.7

- Reapplied the full custom development patch set to the clean v12.0.7.556 production archive.
- Corrected Kaliel attachment to locate the lowest visible generated objective block region, including nested `ContentsFrame.<block>.lastRegion` objects.
- Falls back through `!KalielsTrackerScrollChild`, KT block frames, and the tracker frame only when no live content region is available.
- Preserved the final world/continent/zone hierarchy layouts, compact summary spacing, text clearance, transmog status, expansion-aware currency icons, GameFont usage, and Classic client TOCs.

## Custom - Kaliel content-bottom anchor correction

- Anchor WQT below `KT_ObjectiveTrackerFrame`, not Blizzard `ObjectiveTrackerFrame` or Kaliel's decorative title frame.
- Hook Kaliel's `KT_` objective modules and blocks frame so WQT follows content expansion and collapse.
- Use the active Kaliel content frame for row indentation.

# World Quest Tracker

## [v12.0.7.556](https://github.com/Tercioo/World-Quest-Tracker/tree/v12.0.7.556) (2026-06-18)
[Full Changelog](https://github.com/Tercioo/World-Quest-Tracker/compare/v12.0.1.555...v12.0.7.556) 

- 12.0.7 patch updates  
- Ignore details framework .md files  
- Framework update  
