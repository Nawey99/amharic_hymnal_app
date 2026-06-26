# Localization

## Current Direction

The app is Amharic-first. Visible navigation, onboarding, settings, history, category, donate, bug-report, sheet-music, and key media controls should be Amharic.

## Keep Internal Names English

Do not translate:

- Dart class names
- enum values
- JSON keys
- API field names
- asset file names
- test descriptions unless needed for UI assertions

## User-Facing Text To Keep Amharic

- Navigation labels
- Empty states
- Buttons
- Dialog titles and actions
- Snackbars
- Tooltips
- Form labels and validation
- Sort options

## QA Scan

Use `rg` for candidate English UI strings, then review manually because many matches are comments, identifiers, tests, or proper nouns.

```powershell
rg -n "Settings|Search|Favorites|Category|Submit|Cancel|Clear|Copy|Share|Play|Pause|Error" lib
```
