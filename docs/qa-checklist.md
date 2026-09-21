# QA Checklist

## Flutter

- `flutter analyze`
- `flutter test`
- `flutter build apk --debug`

## Manual Android Checks

- Onboarding fits small screens.
- Bottom navigation shows Number, Index, Categories, Favorites, Settings.
- Settings switches between New SDA, Old SDA, and Hagerigna.
- Number and Index search preserve typed text when collapsed.
- Index sort defaults to number and can switch to name.
- Favorites toggle immediately on detail pages.
- Lyrics zoom affects the lyrics body, not the fixed title header.
- Hymn 1 shows dummy audio; other hymns show audio unavailable.
- Sheet music displays and screenshots are blocked on Android.
- Bug report submits to backend or queues offline.
- Donate PayPal shows a coming-soon dialog and bank fields copy.

## Backend

The app has no backend of its own; everything is the hymnal API
(`amharic_hymnal_backend`).

- `Invoke-RestMethod https://amharichymnalbackend.vercel.app/api/v1/health`
- Send a report from Settings and confirm it appears in the admin console's Reports tab.
