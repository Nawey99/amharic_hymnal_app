# Downloadable Media

## Contract

The Flutter app does not derive media URLs from hymn numbers. Each hymn from
the hymnal API carries explicit file routes for its audio and sheet-music
pages, with each file's SHA-256, size, content type and file name
(`HymnAudioInfo`, `HymnSheetPage`). Relative paths and Flutter asset paths are
rejected because hymn media is not bundled with the application.

The media layer consists of:

- `MediaReference`, which validates remote URLs and downloaded local paths
- `MediaSource`, a remote file plus its checksum, size and extension
- `AudioRepository` and `SheetMusicRepository`, which resolve hymn metadata
- `DownloadRepository`, which exposes download, delete, and clear operations
- `LocalMediaCacheService`, which stores downloaded media in app-support storage
- `SheetMusicBulkDownloadService`, which installs a whole edition's pages

## Download Flow

1. The selected hymn supplies its file routes and their details.
2. The repository checks for a stored copy under the file's checksum.
3. The app asks the user before downloading, showing the size.
4. The API route answers `302` to a short-lived storage URL, which the client
   follows. That URL is never stored; a retry asks the API route again.
5. The response streams to a temporary file while its SHA-256 is computed.
6. Only if the size and checksum match is it renamed into the cache as
   `<sha256>.<ext>`; otherwise it is deleted and the user is told.
7. Audio plays from the downloaded file and sheet music opens from local paths.

Because files are stored by checksum, a page or recording shared by several
hymns or editions is downloaded once. After each content update, files no
stored edition refers to any more are deleted.

## Whole-edition sheet music

Settings → "ኖታዎችን በሙሉ አውርድ" lists every page of the selected edition in one
request, states the size of what is missing, and downloads six files at a time
with a cancel button. A failed page is skipped; running it again fetches only
what is still missing.

## Captions and labels

- A page whose `borrowedFromVersionCode` is set is another book's scan and
  prints that book's number, so the viewer captions it, e.g.
  "ይህ ኖታ ከ2004 ውዳሴ (ቁ. 132) የተወሰደ ነው።"
- Audio with `source: synthesized` is a MIDI rendering; the player shows a
  "መሣሪያ ብቻ" badge and the attribution text.

Web offline media storage is intentionally not implemented. The web UI
handles this as unavailable.
