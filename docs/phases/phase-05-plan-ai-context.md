# Phase 5 — Plan-aware AI + custom context polish

## Goals

Let plan chats safely update plan structure/progress, and polish scoped custom context + memory editors across all scopes.

## Tasks

- [x] Structured “update plan” flow from plan chats (JSON patch / tool-style)
- [x] Apply patches safely to nested nodes + progress
- [x] Context editor for **global / project / plan / chat** (text + file metadata refs)
- [x] Memory capture: manual pin (optional auto-extract later)
- [x] Token/char budget trimming prefers nearer scopes when cutting

## Acceptance criteria

- Chat can **update nested plan nodes and progress safely**.
- Users can edit custom context at all four scopes; merge order remains global → project → plan ancestors → chat.
