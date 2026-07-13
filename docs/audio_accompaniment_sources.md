# Hymnal Accompaniment Discovery

This note tracks web sources found for hymn accompaniment-only audio.

## Generated Index

- `docs/audio_accompaniment_discovery.csv`
- Built from `assets/data/database/SDA_Hymnal.json`
- Uses English titles from both new and old Amharic SDA hymnals
- Merges matching English titles so repeated old/new hymnal songs point to one search row
- Current count: 404 unique English-title rows

## Source Findings

### Strong Legal Candidate

- Hymns for Worship sells SDA Hymnal piano accompaniment MP3 volumes.
- Their product page states the files are accompaniment MP3s for congregational singing, sold as ZIP downloads.
- This is the cleanest source found so far for app-usable audio, but redistribution in this app still needs explicit purchase/license confirmation.

### Possible Candidate, License Unclear

- sdahymnal.net lists a "complete SDA hymnal instrumental" download.
- The page offers a download link, but it does not clearly state copyright ownership or app redistribution rights.
- Do not import these files into the app until permission/licensing is verified.

### Discovery/Search Sources

- YouTube can help identify available instrumental versions, but YouTube audio should not be downloaded or redistributed unless the uploader grants explicit rights.
- HymnCDs offers accompaniment-only church music, but availability should be checked per title and licensing confirmed.

## Import Rule

Only add audio to the backend/app when one of these is true:

1. We own the recording.
2. The church has written permission to use and redistribute it in the app.
3. The source provides a license that allows app redistribution.
4. The audio is public-domain/CC-licensed and the exact license is stored with the media record.

For now, use the CSV for manual search and source review.
