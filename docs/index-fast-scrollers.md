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
