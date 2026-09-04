# DotDotDot AI — Architecture

Local-first Flutter app: **BYOK** (bring your own keys), works offline, all platforms (Android, iOS, Windows, macOS, Linux, Web). No mandatory account. Google Drive is an optional sync overlay; on-device data remains source of truth.

**Implementation status:** Phases 0–8 are implemented in this repo. Desktop runners (`windows/`, `macos/`, `linux/`) are generated.

## Layers (`lib/`)

| Layer | Role |
|-------|------|
| `app/` | MaterialApp, theme, `go_router` |
| `core/` | Errors, `Result`, ids, clocks, logging |
| `data/` | Persistence, secure vault, Drive sync |
| `domain/` | Models, repositories, services (chat, media, plans, memory, context) |
| `ai/` | Model catalog, provider adapters, capability routing |
| `features/` | UI: shell, chat, media, projects, plans, settings, context |
| `design_system/` | Shared tokens and widgets |

```
UI → Riverpod → Domain services → { AI adapters | Sembast | Secure storage | Drive }
```

## Persistence

**Sembast** (+ `sembast_web` on web) is used instead of Drift in this environment — zero codegen, same entity schema as the plan:

- `ProviderAccount`, `ModelCapability`, `Chat`, `Message`, `Project`, `PlanNode`
- `MemoryItem`, `ContextDoc`, `SyncMeta`
- Soft-delete / sync fields: `uuid`, `updatedAt`, `deletedAt`

API keys never live in the DB. Settings rows store a vault ref (`provider_id`); secrets go in **`flutter_secure_storage`** (encrypted local fallback on web — show a security note).

## AI providers

Adapter pattern behind a single interface (`listModels`, `streamChat`, `generateImage` / `Video` / `Audio`). OpenAI, Gemini, and OpenRouter ship first; unsupported modalities throw typed `CapabilityUnsupported`. A bundled + refreshable capability catalog drives picker badges (`chat | image | video | audio | embedding`).

## Context merge order

When building the system prompt, merge scopes then trim to a token/char budget (prefer nearer scopes when cutting):

1. **Global**
2. **Project**
3. **Plan ancestors** (root → parent → … → current plan node)
4. **Chat**

Memory items at those scopes follow the same order.

## Google Drive (optional)

Connect via Google Sign-In + Drive app-folder scope. Encrypted export of local snapshot + media index. Keys stay device-only unless the user opts into “backup keys” (default **off**). Last-write-wins with `*_conflict` copies. App remains fully usable offline without Drive.

## Core libraries

| Concern | Choice |
|---------|--------|
| State | `flutter_riverpod` |
| Routing | `go_router` |
| Local DB | `sembast` / `sembast_web` |
| Secure keys | `flutter_secure_storage` |
| HTTP | `dio` |
| Drive | `google_sign_in` + `googleapis` |
| Media | `file_picker`, `path_provider`, `uuid` |

See [PLAN.md](PLAN.md) for product detail, domain ER diagram, and delivery phases.
