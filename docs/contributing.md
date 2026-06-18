# Contributing

## Local Setup

1. Run `flutter pub get`.
2. Start the content backend from `backend/content` with `npm run dev`.
3. Start the user backend from `backend/user_app` with `npm run dev`.
4. Run Flutter with optional overrides:

```powershell
flutter run -d windows `
  --dart-define=WUDASE_CONTENT_API_URL=http://localhost:8787 `
  --dart-define=WUDASE_USER_APP_API_URL=http://localhost:8790
```

## Change Rules

- Keep `sda_new`, `sda_old`, and `hagerigna` as the stable public version IDs.
- Keep `hymnal` as a compatibility alias only.
- Do not duplicate SDA category ranges; update `HymnCategories` first.
- Do not allow sheet music screenshots or sheet music sharing.
- Run `dart format`, `flutter analyze`, and `flutter test` before submitting.

## Git

Use feature branches, not `main`. Keep commits small enough to review.
