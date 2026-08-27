# Framework Source and Update Policy

The standalone ItE2E snapshot was extracted from `test/e2e` at:

- repository base: `origin/main`
- source commit: `c4b1f7d230ed0d411bfc79a2c396f80073b5e902`
- extraction date: 2026-08-20

Included upstream surfaces:

- `test/e2e/ItE2E/**`
- deterministic `test/e2e/fixtures/**`
- Unit and Live self-tests
- the local HTML/NUnit/Markdown report runner

Excluded by design:

- feature-specific suites, including Markdown tests
- release-checklist wiring and online automation
- authenticated AI-oracle tests
- policy/elevation helpers
- screenshots, logs, provider homes, wire captures and local artifacts

Local additions:

- verified HWND/PID identity
- left/right client-coordinate single/double click through Win32 `SendInput`
- named OS key chords
- deterministic Win32 input probe
- deterministic offline ACP agent-input self-test
- explicit opt-in guard for the copied optional AI oracle
- build receipt and deployment freshness validation
- portable TDD workflow and tool/build documentation

This directory is intentionally a snapshot so one commit remains cherry-pickable
even if `main` later restructures `test/e2e`. To update it, compare the source
directories at a named main commit, port only relevant framework changes, rerun all
self-tests, and update the source commit above. Do not blindly recopy feature suites.