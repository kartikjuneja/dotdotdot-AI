# Phase 7 — Google Drive optional sync

## Goals

Optional encrypted backup/sync via Google Drive app folder while keeping local data source of truth and offline use intact.

## Tasks

- [x] Google Sign-In connect / disconnect in Settings
- [x] Drive app-folder (restricted) scope
- [x] Encrypted backup package of Sembast snapshot + media index
- [x] Exclude API keys by default; optional “backup keys” toggle (default off)
- [x] Change log → push/pull; last-write-wins + `*_conflict` copies
- [x] Sync status UI + first-run restore
- [x] Soft-delete / `uuid` + `updatedAt` merge semantics

## Acceptance criteria

- Two devices/sessions can **restore chats/projects/plans via Drive**.
- App remains fully usable **offline** without Drive; local-first preserved.
