# WorldQuestTracker multi-client behavior

This package uses client-specific TOC files.

- Retail / Mainline loads the complete WorldQuestTracker addon.
- Classic Era, Burning Crusade Anniversary, Wrath/Titan, and Mists of Pandaria Classic load a small compatibility module only.
- The compatibility module does not load Retail XML, map templates, task-quest APIs, transmog APIs, or bundled UI libraries.
- `/wqt` explains that the current Classic client does not expose the Retail World Quest system.

The Classic files are intentionally load-safe rather than feature-equivalent. Current Classic clients do not have Retail-style World Quests to display.
