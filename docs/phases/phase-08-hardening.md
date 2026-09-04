# Phase 8 — Hardening

## Goals

Production-ready reliability: errors, rate limits, prompt budgets, tests, a11y/responsive polish, and release checklists.

## Tasks

- [x] User-facing error surfaces; redact secrets in logs
- [x] Rate-limit handling and retries (dio interceptors)
- [x] Prompt budget trimming hardened across scopes
- [x] Tests: Sembast repos, provider adapters (mocked HTTP), plan tree reducers, sync merge
- [x] Accessibility + responsive polish (drawer vs modal nav)
- [x] Release checklists per platform (Windows, Web, Android, iOS, …)

## Acceptance criteria

- Critical paths covered by tests above.
- Polished UX on primary targets (Windows/Web); release checklists written and usable.
- No keys in logs; BYOK privacy expectations from the plan held.
