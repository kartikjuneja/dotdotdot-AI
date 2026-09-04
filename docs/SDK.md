# Flutter SDK setup

## Status

Desktop runners (`windows/`, `macos/`, `linux/`) are in the repo. Install the Flutter SDK locally, then run from the project root.

## Install Flutter

1. Download the stable SDK from [flutter.dev/docs/get-started/install](https://docs.flutter.dev/docs/get-started/install).
2. Extract to a path without spaces (e.g. `%USERPROFILE%\dev\flutter` on Windows — no admin required).
3. Add `flutter\bin` (or `flutter/bin`) to your **user** `PATH`.
4. Open a new terminal and verify:

```bash
flutter --version
flutter doctor
```

This repo was last built against Flutter **3.47.x** (Dart 3.13). Prefer the current stable channel.

## After install — this repo

```bash
flutter pub get
flutter run -d chrome
flutter run -d windows
```

Also valid once device tooling is ready: Android / iOS / macOS / Linux as listed by `flutter devices`.

## Notes

- `flutter pub get` needs network for pub.dev.
- See [ARCHITECTURE.md](ARCHITECTURE.md) and [PLAN.md](PLAN.md) for app design.
- Deploy / GitHub Pages: see the root [README](../README.md).
