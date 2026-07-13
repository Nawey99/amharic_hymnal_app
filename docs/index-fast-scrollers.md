# Index Fast Scrollers

## Amharic/Fidel Mode

Sort-by-name mode uses a right-side Amharic Fidel rail. It groups syllables to base Fidel letters using the required order:

`ሀ ለ ሐ መ ሠ ረ ሰ ሸ ቀ በ ቨ ተ ቸ ኀ ነ ኘ አ ከ ኸ ወ ዐ ዘ ዠ የ ደ ጀ ገ ጠ ጨ ጰ ጸ ፀ ፈ ፐ`

Examples:

- `ሙሉ` -> `መ`
- `ስም` -> `ሰ`
- `ቫን` -> `ቨ`
- `እናት` -> `አ`
- `ፓስታ` -> `ፐ`

Unsupported, Latin, emoji, number-only, or empty values map to `#` and are not shown on the visible rail.

## Numeric Mode

Sort-by-number mode uses digits `0 1 2 3 4 5 6 7 8 9`.

The rail maps by first meaningful digit and jumps to the nearest available section if the exact digit is absent.

## Interaction

The shared `IndexedFastScroller` supports tap, vertical drag, haptic selection feedback, and a large floating bubble while dragging.
# Final QA Update

The numeric fast scroller now uses hymn ranges generated from the active maximum hymn number instead of digit buckets. For a 325-song hymnal, the rail labels are:

`1-50`, `51-100`, `101-150`, `151-200`, `201-250`, `251-300`, `301-325`

The Amharic Fidel rail remains fixed and uses the existing Fidel normalization table. The selection bubble now follows the user's tap/drag position.
