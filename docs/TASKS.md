# DotDotDot AI — Master task checklist

Track progress here. Per-session: pick the next unchecked item, implement, mark done. Detail and acceptance criteria live under [`phases/`](phases/).

All phase checklist items below are marked complete for the current codebase.

---

## Phase 0 — Bootstrap & engineering baseline

- [x] Copy / scaffold Flutter multi-platform shell (`dotdotdot_ai`)
- [x] Clean `lib/`, theme tokens, `go_router` stub, Riverpod root
- [x] `analysis_options.yaml`, folder conventions, README run targets
- [x] App launches on Windows or Web with empty shell UI

→ [phase-00-bootstrap.md](phases/phase-00-bootstrap.md)

## Phase 1 — Local data + secure keys

- [x] Sembast schema for providers, chats, messages, projects, plans, memory, context, sync meta
- [x] Secure storage vault for API keys
- [x] Settings UI: add/remove provider keys (OpenAI, Gemini, OpenRouter)
- [x] Keys persist across restart; CRUD chats/projects without AI calls

→ [phase-01-local-data.md](phases/phase-01-local-data.md)

## Phase 2 — Chat + model catalog

- [x] Provider adapters + streaming chat (OpenAI-compatible / OpenRouter, then Gemini)
- [x] Bundled capability catalog + model picker badges
- [x] Sidebar chat list, new chat, composer, streaming UI
- [x] Chat with a real key; capability badges visible

→ [phase-02-chat-catalog.md](phases/phase-02-chat-catalog.md)

## Phase 3 — Projects & chat organization

- [x] Projects CRUD; assign/move chats; project default model
- [x] Project-scoped memory + context docs
- [x] Move chat in/out of project; project context affects replies

→ [phase-03-projects.md](phases/phase-03-projects.md)

## Phase 4 — Nested plans/courses + progress

- [x] Plan tree UI (infinite nesting), progress 0–100, reorder
- [x] Plan-scoped chats; memory/context inheritance up ancestors
- [x] Manual plan edit + progress updates
- [x] Multi-level course tree with scoped chat

→ [phase-04-plans.md](phases/phase-04-plans.md)

## Phase 5 — Plan-aware AI + custom context polish

- [x] Structured “update plan” from plan chats (JSON patch / tool-style)
- [x] Global / project / plan / chat context editor
- [x] Memory capture (manual pin; optional auto-extract later)
- [x] Chat can update nested plan nodes and progress safely

→ [phase-05-plan-ai-context.md](phases/phase-05-plan-ai-context.md)

## Phase 6 — Media generation

- [x] Image generation adapters + gallery in chat
- [x] Audio where provider supports
- [x] Video where provider supports; clear unsupported UX
- [x] Local media cache under app documents
- [x] Image path solid; video/audio graceful by capability

→ [phase-06-media.md](phases/phase-06-media.md)

## Phase 7 — Google Drive optional sync

- [x] Google Sign-In connect/disconnect
- [x] Encrypted backup package (exclude keys by default)
- [x] Sync status UI, conflict handling, first-run restore
- [x] Restore across devices/sessions without losing offline local-first use

→ [phase-07-drive-sync.md](phases/phase-07-drive-sync.md)

## Phase 8 — Hardening

- [x] Error surfaces, rate-limit handling, prompt budget trimming
- [x] Tests: repos, mocked adapters, plan tree reducers, sync merge
- [x] Accessibility + responsive polish; release checklists per platform

→ [phase-08-hardening.md](phases/phase-08-hardening.md)
