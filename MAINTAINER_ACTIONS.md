# Maintainer Actions

- Replace placeholder PayPal and National Bank details before public release.
- Set production `WUDASE_CONTENT_API_URL` and `WUDASE_USER_APP_API_URL`.
- Create named production Owner, Reviewer, and Editor accounts; keep
  `ALLOW_LEGACY_CONTENT_ADMIN=false` so the shared recovery token cannot bypass
  per-person audit history.
- Set production `USER_APP_ADMIN_TOKEN`.
- Review `content_import_issues` after each content import.
- Run `npm.cmd run db:deploy`; it applies shared catalog migrations to both
  databases and collaboration/review migrations only to the SDA control database.
- Add real audio metadata and enable downloads behind `DownloadRepository`.
- Verify screenshot blocking on physical Android before release.
