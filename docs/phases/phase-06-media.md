# Phase 6 — Media generation

## Goals

Image (and where supported, audio/video) generation via provider adapters, shown in chat, with local media caching and capability-gated UX.

## Tasks

- [x] Image generation adapters + gallery in chat
- [x] Audio generation where provider supports
- [x] Video generation where available; catalog marks experimental; clear unsupported UX
- [x] Local media cache under app documents (`path_provider`)
- [x] Disable generate actions when model lacks modality (capability-first)

## Acceptance criteria

- **Image path is solid** end-to-end with a supporting key/model.
- Video/audio fail gracefully via capability badges / `CapabilityUnsupported` — no opaque crashes.
