# Mobile QA Checklist

Verify on Android portrait and landscape:

- 360x640
- 375x667
- 390x844
- 412x915
- large font scale

## Screens

- Onboarding has no overflow and is fully Amharic.
- Bottom navigation order is `ምድብ`, `ማውጫ`, `ቁጥር`, `ተወዳጅ`, `ቅንብር`.
- Number page opens by default and the `ታሪክ` chip is visible.
- Category page uses icons, not images.
- Index name sort shows Amharic Fidel rail only.
- Index number sort shows numeric rail only.
- Favorites remain separate when switching versions.
- Settings dropdowns do not show a strong active border.
- Contribute opens `https://github.com/Nawey99/amharic_hymnal_app`.
- Donate shows `በባንክ ለማስተላለፍ`, no branch field, and only account number copies.
- Report bug opens email composer to `nawey99@gmail.com`.
- Lyrics header shows `- number -`.
- Sheet music access is beside audio and opens full screen with X close.
- Hymn 1 dummy audio is audible.

## Commands

```powershell
flutter clean
flutter pub get
dart format .
flutter analyze
flutter test
flutter build apk --release
flutter run -d android
```
