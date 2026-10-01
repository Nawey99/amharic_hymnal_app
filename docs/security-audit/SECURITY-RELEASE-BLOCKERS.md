# Security Release Blockers

Audit date: 2026-10-01.

## Result: no security release blocker was found

None of the 27 findings meets the blocker rule. Checked against each blocker
category:

| Blocker category | Result | Evidence |
| --- | --- | --- |
| Exposed privileged credentials | None exposed | Release APK contains no key, token or DSN. Both repositories' full history is clean. Privileged values exist only in local git-ignored files (F-02). |
| Authentication bypass | None | Admin routes answer 401 with no token, a junk token, an `alg=none` token and an HS256-forged token. |
| Authorization bypass / unintended admin access | None | Every admin route sits behind `requireAuthenticationConfigured`, `requireAuthentication` and `requireRole` (`router.ts:240-245`). |
| Sensitive data, database or storage exposure | None | Anon key reads no table (`api_disabled` schema) and no bucket. Objects need a valid signature. |
| Arbitrary file write, command execution, injection | None | Cache file names are a SHA-256 plus a regex-checked extension. All backend SQL is parameterised. No process execution in the app. |
| Token compromise, cryptographic failure | None | The app holds no token. JWTs are verified against JWKS with issuer, audience and algorithm pinned. |
| Debug or admin functionality in production | None exploitable | Test scaffolding is present in the APK (F-05) but exposes no capability. |
| Signing-key exposure | None | Keystore and passwords are local and untracked (F-14). |
| Critical dependency vulnerability with practical impact | None confirmed | F-09 is reachable only from an operator CLI. |
| Insecure transport | None | Cleartext disabled in the release manifest; HTTPS enforced in release config; HSTS served. |

## Conditions that would change this

These are not blockers today. Each becomes one if the stated condition is true,
and none of the conditions could be checked from this machine.

| Finding | Becomes a blocker if | How to check |
| --- | --- | --- |
| F-02 | The old `SUPABASE_ACCESS_TOKEN`, or any file in `D:\Church\App\backups\`, has been copied off this machine (cloud sync, shared drive, chat) and the token is still valid | Supabase dashboard, Account, Access Tokens |
| F-04 | The backend repository is made public or gains collaborators who should not read report contact details | GitHub repository settings |
| F-14 | `wudase-upload.jks` is the app signing key rather than a resettable upload key, and it has no backup | Play Console, App integrity |

## Should be done before release although not blockers

F-01 is the one finding where the published privacy policy and the running
system disagree: the policy says analytics are deleted after 90 days, and the
job that deletes them cannot authenticate. Fix it, or change the policy wording,
before the store listing points at that policy.
