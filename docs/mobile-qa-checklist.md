# Mobile QA Checklist

## Devices And Sizes

Check portrait and landscape where possible:

- 360x640
- 375x667
- 390x844
- 412x915

## Startup

- Native splash appears first with the app logo.
- In-app splash uses the same visual language and only covers initialization.
- No Flutter default icon appears.

## Onboarding

- Fully Amharic text.
- No overflow on small phones or landscape.
- Guide images under `assets/onboarding/` render.
- `ዝለል`, `ቀጣይ`, and `ጀምር` work.

## Navigation

- Order is `ምድብ`, `ማውጫ`, `ቁጥር`, `ተወዳጅ`, `ቅንብር`.
- Default tab is `ቁጥር`.
- Hagerigna hides `ምድብ`; `ቁጥር` remains selected.
- Keyboard does not push nav into content.

## History

- Open a hymn and confirm it appears in history.
- Switch old/new hymnal and confirm history respects version.
- Swipe a history item to delete it.
- Clear all history and confirm Amharic empty state.

## Index

- Sort dialog open/dismiss does not change sort.
- `በቁጥር` and `በስም` switch repeatedly.
- Alphabet rail is fixed and only contains non-empty groups.
- Number rail jumps near the chosen range.

## Lyrics And Media

- Header shows hymn number and title once.
- Sheet music icon is visible beside favorite.
- Pinch zoom works across the lyrics content area.
- Sheet music page uses app background/theme and zooms across the viewer.
- Audio dummy appears only for hymn 1.
- Background audio notification remains a production follow-up; see `docs/audio-background-playback.md`.

## Settings And Donate

- Dropdowns are non-editable and visually aligned.
- Contribute opens `https://github.com/Nawey99/amharic_hymnal_app`.
- Donate PayPal shows Amharic coming-soon text.
- Bank fields can be copied.

## Verification Commands

```powershell
flutter clean
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --debug
```
