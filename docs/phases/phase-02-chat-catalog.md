# Phase 2 — Chat + model catalog

## Goals

Streaming chat against real BYOK providers, with a capability-aware model catalog and a ChatGPT-like conversation UI.

## Tasks

- [x] `AiProvider` adapter interface + OpenAI-compatible / OpenRouter streaming
- [x] Gemini adapter
- [x] Bundled model capability catalog; optional live list merge
- [x] Model picker with badges (`chat | image | video | audio`)
- [x] Sidebar chat list + new chat
- [x] Message composer + streaming UI
- [x] Inject merged context/memory when present (global → project → plan → chat) with budget trim hooks

## Acceptance criteria

- User can chat with a **real API key** and see streaming replies.
- Capability badges appear in the model picker; unsupported modalities are clear in UI.
