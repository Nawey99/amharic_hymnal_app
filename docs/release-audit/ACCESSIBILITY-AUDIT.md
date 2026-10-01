# Accessibility & Localisation Audit — Phase 1

Audit date: 2026-10-01 · Commit `b4d78a0` · Read-only. No TalkBack/VoiceOver session was run
in this phase; screen-reader behaviour is inferred from code and from the existing automated
guideline tests.

## Existing automated coverage (CONFIRMED)
`test/accessibility/` runs Flutter's `androidTapTargetGuideline`, `iOSTapTargetGuideline`,
`labeledTapTargetGuideline` and `textContrastGuideline`. `test/core/palette_contrast_test.dart`
asserts 4.5:1 for body text across 15 themes and 3:1 for the index section letter.
14 `IconButton`s, 14 tooltips. 16 explicit `Semantics` wrappers.

## Blockers
None found that would prevent a screen-reader user from completing core tasks
(find a hymn by number, open it, read it), based on code. Not verified with a screen reader.

## Findings

### A11Y-01 — Next/previous hymn is swipe-only · MEDIUM · CONFIRMED
`hymn_detail_page.dart:269-290` handles horizontal drags; there are no buttons and no
`CustomSemanticsAction` anywhere in `lib/` (grep: none). TalkBack/VoiceOver users, and anyone
who cannot swipe precisely, must go back to a list to reach the next hymn. Direction: add
semantic custom actions (and optionally visible buttons).

### A11Y-02 — Pinch-to-resize lyrics has a Settings alternative · INFO
The font-size slider in Settings covers it (`appearance_settings.dart`).

### A11Y-03 — System text size is capped at 200 % · LOW · CONFIRMED
`app_text_scope.dart:18-27` clamps the system scale to 1.0–2.0. iOS accessibility sizes go
beyond 3×. The lyrics have their own size (up to 40) seeded from the system scale
(`settings_service.dart:35-43`), so reading is covered; chrome text stops growing at 2×.
A floor of 1.0 also ignores users who chose *smaller* text.

### L10N-01 — English error messages on Amharic screens · MEDIUM · CONFIRMED
`hymns_bloc.dart:129, 131, 206, 342, 352` emit English sentences
("Hymns could not be loaded. Please try again." etc.), rendered verbatim on Categories,
Category hymns, Favourites, History and Index (`*.dart` `state.message`). The guard test
(`test/core/shell_is_translatable_test.dart`) only detects **Amharic** literals, so English
literals pass it. Direction: emit failure *kinds* from the bloc and localise in the widget;
extend the guard to user-visible English.

### L10N-02 — Other English-only strings · LOW · CONFIRMED
- Android notification channel name/description (`global_audio_service.dart:32, 78-79`).
- `AudioRepository` fallback title `'Hymn #$hymnNumber'` (`media_repositories.dart:92`), used as
  the lock-screen title when a hymn has no title.
- The English UI strings (181 added recently) are a first draft and have not been reviewed by a
  native speaker.

### L10N-03 — Ethiopic ordering and fonts · INFO (pass)
- Index alphabet in `index_section_utils.dart` matches the required order exactly (34 letters,
  ሀ ለ ሐ መ ሠ ረ ሰ ሸ ቀ በ ቨ ተ ቸ ኀ ነ ኘ አ ከ ኸ ወ ዐ ዘ ዠ የ ደ ጀ ገ ጠ ጨ ጰ ጸ ፀ ፈ ፐ); each base letter
  groups its orders (e.g. `'ሐ': 'ሐ ሑ ሒ ሓ ሔ ሕ ሖ ሗ'`). Verified by script, 2026-10-01.
- Noto Sans Ethiopic ships in 400/600/700; Noto Serif (no Ethiopic glyphs) always names
  Noto Sans Ethiopic as fallback (`app_fonts.dart`).
- iOS does not declare Amharic as a supported localisation (IOS-05).

### Responsive layout (INFO — not audited per screen on devices)
Orientation is unlocked on both platforms and iPad is supported. Recent work fixed a 1.2 px
overflow in the title bar with the serif face; no systematic sweep across small phones
(320 dp), tablets, foldables, split screen and 200 % text was done in this phase. Recommend a
widget-test matrix (sizes × text scales × locales) for the five tabs, the hymn page and the
player in Phase 2.
