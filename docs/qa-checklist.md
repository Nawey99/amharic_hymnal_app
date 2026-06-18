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
- Donate PayPal opens externally and bank fields copy.

## Backend

- `node --check backend/content/src/server.js`
- `node --check backend/user_app/src/server.js`
- `Invoke-RestMethod http://localhost:8787/health`
- `Invoke-RestMethod http://localhost:8790/health`
