# Phase 0 — Bootstrap & engineering baseline

## Goals

Stand up a runnable multi-platform Flutter shell for `dotdotdot_ai` with routing, Riverpod, theme tokens, and folder conventions so later phases can land features cleanly.

## Tasks

- [x] Install Flutter if needed (see [SDK.md](../SDK.md)); ensure SDK is on PATH
- [x] Scaffold or copy multi-platform shell; package name `dotdotdot_ai`
- [x] If desktop folders missing: `flutter create . --platforms=windows,macos,linux`
- [x] Clean `lib/` layout: `app/`, `core/`, `data/`, `domain/`, `ai/`, `features/`, `design_system/`
- [x] Theme tokens + empty shell UI (sidebar scaffold)
- [x] `go_router` stub routes; Riverpod `ProviderScope` root
- [x] `analysis_options.yaml`, folder conventions documented
- [x] README with run targets per platform
- [x] `flutter pub get`; launch on Windows or Chrome

## Acceptance criteria

- App launches on **at least Windows or Web** with an empty shell UI (nav scaffold acceptable).
- Package / folder conventions match [ARCHITECTURE.md](../ARCHITECTURE.md).
- No AI or persistence required yet beyond a compiling shell.
