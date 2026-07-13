# ውዳሴ

ውዳሴ is a Flutter hymnal app for Amharic SDA church members. The app currently includes the Amharic SDA Hymnal and Hagerigna Amharic worship songs, with a roadmap for more Ethiopian languages and books in future releases.

## Current Direction

- Keep this Flutter app as the source of truth.
- Use older Xamarin/Flutter hymnal apps only as feature inspiration.
- Prioritize Android and iOS, while keeping web important.
- Keep lyrics available offline.
- Move large sheet music toward a hybrid remote plus offline-cache model.
- Preserve a scalable feature-based architecture for future hymnals and languages.

## Development

```powershell
flutter pub get
flutter analyze --no-pub lib test integration_test
flutter test --no-pub
```

## Key Docs

- [Product decisions](docs/PRODUCT_DECISIONS.md)
- [Architecture](docs/architecture.md)
- [Lyrics feature](docs/lyrics-feature.md)
- [Handoff](docs/Handoff.md)
