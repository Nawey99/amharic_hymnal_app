# ውዳሴ Product Decisions

This document captures maintainer decisions for the modernization work.

## Product Direction

- App name: ውዳሴ
- Primary audience: Amharic SDA church members.
- Future audience: additional Ethiopian-language communities, starting with Afaan Oromo.
- Design direction: calm church/devotional tone with a premium Bible-app feel.
- Typography priority: Amharic reading comfort is a primary UX requirement.

## Scope

- Keep this Flutter project as the source of truth.
- Use the Xamarin reference only for product ideas and feature comparison.
- Do not copy code, assets, or data from the reference app.
- Current launch content remains:
  - Amharic SDA Hymnal
  - Hagerigna Amharic worship songs
- Future releases may add more hymnals/books/languages.

## Platform Targets

- Primary: Android and iOS.
- Important secondary target: web.

## Feature Decisions

- Onboarding is required.
- Home should prioritize hymn-number lookup while still surfacing search, index, favorites, history, and categories.
- Search is scoped to the selected hymnal/book.
- Latin transliteration search is not required for launch.
- Amharic phonetic/same-sound matching is required where practical.
- Each hymn belongs to one category.
- Favorites should update optimistically and eventually support user ordering.
- History is automatic, with clear-all and delete-single-item controls.
- Users may share lyrics.
- Sharing sheet music and screenshot-style sharing of sheet music is forbidden.
- Lyric mistake reporting is required from settings/support areas, not from the primary hymn reading screen.

## Media Strategy

- Sheet music strategy: hybrid.
  - Lyrics/data should be available offline.
  - Sheet music should move out of the app bundle and be downloaded/cacheable.
  - Previously downloaded sheet music should remain available offline.
- Audio is a launch feature.
  - Use remote audio with caching or resilient streaming.
  - Avoid secrets in source code.

## Architecture Direction

- Keep a scalable feature-based architecture.
- Preserve the current Clean Architecture direction where it helps long-term maintainability.
- Prefer reusable domain/data services for future hymnals and languages.
- Make changes incrementally with analyzer/test verification before major UI rewrites.

## Release Readiness Defaults

- Theme should follow the system, with explicit light and dark themes.
- App package metadata, README, support links, donation links, and signing config must be productionized before store release.
- Large generated/build artifacts must stay out of Git.
