# Phase 1 — Local data + secure keys

## Goals

On-device persistence for core entities and a secure vault for BYOK API keys, with Settings UI to manage providers — no live AI calls required.

## Tasks

- [x] Sembast (+ `sembast_web`) stores for: providers, chats, messages, projects, plan nodes, memory, context, sync meta
- [x] Same entity fields as plan (`uuid`, `updatedAt`, `deletedAt` soft delete)
- [x] `flutter_secure_storage` vault; settings rows reference keys by `provider_id` only
- [x] Settings UI: add/remove keys for OpenAI, Gemini, OpenRouter
- [x] Repository CRUD for chats and projects
- [x] Web security note if using encrypted local fallback

## Acceptance criteria

- Keys **persist across restart** and never appear in the Sembast DB or logs.
- User can CRUD chats/projects locally **without** AI network calls.
