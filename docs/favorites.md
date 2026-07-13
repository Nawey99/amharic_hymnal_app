# Favorites

Favorites are now keyed by hymnal version and song number:

`version:number`

Examples:

- `sda_new:1`
- `sda_old:1`
- `hagerigna:7`

The public settings repository still exposes `List<int>` for the currently selected version to preserve older call sites. Existing number-only favorites are migrated into the currently selected version the first time they are read.
