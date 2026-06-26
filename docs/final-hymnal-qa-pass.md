# Final Hymnal QA Pass

Branch: `fix/final-hymnal-qa-pass`

## Implementation Checklist

1. App size and assets: measured source/build sizes, kept sheet music/audio out of the base Flutter asset bundle, optimized image assets, and replaced the dummy WAV with the supplied audible MP3.
2. Splash screen: inspected Android native launch theme and in-app splash. Native splash remains first; in-app splash is used for initialization with a bounded minimum duration.
3. Onboarding: existing onboarding assets are registered and mobile widget coverage verifies small portrait sizes without overflow. Landscape remains manual QA.
4. Navigation bar: active item no longer has a selected pill background/border, selected state changes color/size only, and the Number tab uses the same icon for active/inactive states.
5. Number page: header now says `ውዳሴ`; invalid/empty/out-of-range numbers show Amharic validation and do not navigate.
6. Category page: category entries use mapped Material icons, follow the shared background preference, and keep list layout.
7. Index sort and keyboard: search fields no longer autofocus when opened; sort behavior remains explicit through the sort dialog.
8. Numeric fast scroller: rail now uses generated hymn ranges such as `1-50`, `51-100`, and `301-325` instead of digit buckets.
9. Amharic Fidel fast scroller: existing Fidel normalization is preserved; bubble now follows the drag/tap position.
10. Lyrics header: existing detail header uses `- number -`; title/English subtitle behavior remains covered by existing UI/tests.
11. English title cleanup: reusable `cleanEnglishTitle` remains in place with tests.
12. Lyrics audio and sheet music: audio/sheet music repositories remain in place; dummy audio now uses the supplied audible MP3.
13. Background audio notification: not implemented in this pass. Current playback still uses `audioplayers`, which does not provide full Android media notification controls in this app. Maintainer action: migrate `GlobalAudioService` to `audio_service` + `just_audio`/`just_audio_background`.
14. Lyrics pinch zoom: existing font-size zoom remains scoped under the fixed header/media area.
15. Favorites per version: existing version-aware settings/history/favorite work remains in place; favorite regression tests pass.
16. Settings page: GitHub link target remains `https://github.com/Nawey99/amharic_hymnal_app`; dropdown polish remains in the current settings tile implementation.
17. Donate page: bank label is `በባንክ ለማስተላለፍ`; branch is absent; only the bank/account number field is copyable.
18. Report bug: submission opens a `mailto:` composer addressed to `nawey99@gmail.com` with user input and app metadata.
19. Keyboard focus: Number, Index, and Favorites search fields no longer force autofocus when the search UI is opened.
20. Amharic localization: touched user-facing validation/search/nav strings are Amharic; full string audit remains ongoing as content grows.
21. Tests: added/updated tests for numeric range rail, media asset, and selected nav icon behavior.
22. Documentation: this file records the final QA status; app-size/media docs should be kept current as backend media hosting lands.
23. Git branch and push: use `fix/final-hymnal-qa-pass`; do not push to main.
24. Final recheck: run `flutter clean`, `flutter pub get`, `dart format .`, `flutter analyze`, `flutter test`, and release builds before merge.

## Size Findings

Windows measurement before final clean:

- Repository working folder: 1790.72 MB
- `assets`: 61.22 MB
- `assets/audio`: 0.71 MB
- `assets/category`: 0.84 MB
- `assets/images`: 0.18 MB
- `assets/onboarding`: 0.02 MB
- `assets/sheet_music`: 58.44 MB
- `build`: 178.97 MB

Largest current source asset is `assets/audio/dummy_hymn_1.mp3` at 0.71 MB. Sheet music is present in the repo for backend/CDN/local development, but is not registered as a bundled Flutter asset.

Final release size checks:

- Multi-ABI release APK: 28.7 MB
- `android-arm64` release APK with `--analyze-size`: 14.1 MB
- `android-arm64` release AAB with `--analyze-size`: 15.8 MB

## Maintainer Actions

- Implement Android lock-screen/media notification controls by migrating to `audio_service` and `just_audio`.
- Replace onboarding guide cards with real device screenshots when final UI screenshots are approved.
- Host sheet music and future audio through the backend/CDN and store file sizes in API metadata for download prompts.
