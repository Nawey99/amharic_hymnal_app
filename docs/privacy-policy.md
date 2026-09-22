# Privacy Policy — ውዳሴ (Wudase)

> **Before publishing:** replace every `[[...]]`, have the text reviewed, and
> check the Amharic summary with a native speaker. The published copy is
> `web/privacy.html`; keep the two in step.

**Effective date:** [[date of publication]]
**Publisher:** [[name of the person, church or organisation responsible, e.g. Filowha Seventh Day Adventist Church]]
**Contact:** [[email address for privacy questions]]

## In short

- No account, no sign-in, no advertising, no tracking across apps.
- Your settings, favourites, history and searches stay on your phone.
- The app sends anonymous counts of which hymns are opened (kept 90 days),
  and reports only when you choose to send one.
- Test (beta) versions may send crash reports. Public versions do not.

## What stays on your phone

These never leave your device:

- your chosen hymnal, language, font size and other settings;
- your favourite hymns and the hymns you have recently opened;
- the hymns, audio and sheet music the app has downloaded, so they work
  offline;
- anything you type into the app's search. Search runs on your phone and is
  not sent anywhere.

Uninstalling the app, or clearing its storage, deletes all of this.

## What the app sends, and why

### 1. Downloading hymns, audio and sheet music
The app downloads hymn content from our server (the hymnal API) and audio and
sheet-music files from our file storage. As with any internet request, these
services see your IP address while answering. It is not stored with any hymn
data. A short-lived counter per IP address is kept only to stop abuse (rate
limiting).

### 2. Anonymous usage counts
When you open a hymn or a category, the app sends which hymn or category it
was, in which hymnal, and whether it was opened from the list, search or
favourites. This shows us which hymns people use. The count contains **no**
name, account, device ID, IP address or location, and is deleted after
**90 days**.

### 3. Reports you choose to send
If you send a report (a wrong lyric, a problem with the app, a suggestion) we
receive:

- what you wrote and the type of report you chose;
- the hymnal and hymn it is about, if any;
- the app version, platform, operating-system version, phone model, the
  screen you were on and the app language, to help us fix the problem;
- a contact email or phone number **only if you type one**, so we can reply.

We do not store your IP address with a report. If you are offline, the report
waits on your phone (encrypted) and is sent the next time the app can reach
the server. Reports are read only by the people who maintain the hymnal and
kept for [[how long, e.g. "until resolved, and at most 12 months"]].

### 4. Crash reports (test versions only)
Test (beta) versions may send a crash report when the app fails: the error,
where in the app it happened, the app version, and the phone model and
operating system. Crash reports contain no name, account, IP-derived data or
screenshots. **Public versions of the app never send crash reports.** Crash
reports are processed by Sentry (sentry.io) and kept for
[[Sentry retention, e.g. 30 or 90 days per your Sentry plan]].

## Who processes the data

We do not sell or share your data, and we do not use it for advertising. These
providers run the service for us and process data only for that purpose:

| Provider | What it does for us |
|---|---|
| Vercel | runs the hymnal API |
| Supabase | stores hymn content, reports, anonymous usage counts, and audio and sheet-music files |
| Upstash | short-lived rate-limit counters |
| Sentry | crash reports from test versions only |

These providers may process data outside Ethiopia.

## Security

All connections use encrypted HTTPS. Reports and usage counts can only be read
by signed-in maintainers of the hymnal. Downloaded files are checked against a
checksum before the app uses them.

## Permissions the app uses (Android)

- **Internet**: to download hymns, audio and sheet music, and to send reports.
- **Foreground service (media playback)** and **wake lock**: to keep playing
  a hymn when the screen is off, and to keep the screen on while you read if
  you turn that setting on.

The app blocks screenshots of sheet music to respect the rights of its
publishers.

## Children

The app is suitable for all ages. It does not knowingly collect personal
information from children, and a report only contains contact details if
someone types them in.

## Your choices and rights

- You can use the whole app without sending a report.
- Uninstall the app, or clear its storage, to delete everything on your phone.
- To see, correct or delete a report you sent, email [[email address]] with
  roughly when you sent it and what it said. We will reply within
  [[e.g. 30 days]].

## Changes

If this policy changes, we will update the effective date above and, for
important changes, tell you in the app.

---

## በአጭሩ (Amharic summary — for review)

- ውዳሴ መለያ ወይም መግቢያ አይፈልግም፤ ማስታወቂያም የለውም።
- ቅንብሮችዎ፣ ተወዳጆችዎ፣ ታሪክዎ እና ፍለጋዎ በስልክዎ ላይ ብቻ ይቀመጣሉ።
- መተግበሪያው የትኞቹ መዝሙሮች እንደተከፈቱ ስም-አልባ ቁጥር ይልካል (ለ90 ቀናት ይቀመጣል)።
- ሪፖርት የሚላከው እርስዎ ሲልኩ ብቻ ነው፤ የመገናኛ አድራሻ የሚካተተው እርስዎ ከጻፉት ብቻ ነው።
- የሙከራ (ቤታ) ስሪቶች የብልሽት ሪፖርት ሊልኩ ይችላሉ፤ ለሕዝብ የሚለቀቁ ስሪቶች አይልኩም።
- ጥያቄ ካለዎት፦ [[email address]]

---

## Appendix: Google Play "Data safety" answers

For the Play Console form (App content → Data safety). Keep them in step with
the policy above.

| Question | Answer |
|---|---|
| Does your app collect or share any of the required user data types? | Yes (collects; does not share) |
| Is all user data encrypted in transit? | Yes |
| Do you provide a way for users to request that their data be deleted? | Yes, by email (reports); on-device data is deleted by uninstalling |
| **App activity → App interactions** | Collected, not shared, processed ephemerally: no. Optional: no (automatic). Purpose: Analytics. Anonymous hymn/category view counts. |
| **App info and performance → Crash logs** | Collected (beta builds only), not shared. Purpose: App functionality / diagnostics. |
| **App info and performance → Diagnostics** | Collected when the user sends a report (app version, OS, model). Optional: yes. Purpose: App functionality. |
| **Personal info → Email address / Phone number** | Collected only if typed into a report. Optional: yes. Purpose: Developer communications. |
| **Messages → Other in-app messages** | The report text. Optional: yes. Purpose: App functionality. |
| Location, contacts, photos, audio recordings, financial info, device IDs | Not collected |
