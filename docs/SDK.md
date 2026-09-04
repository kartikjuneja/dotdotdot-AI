# Flutter SDK setup (this environment)

## Status

The Flutter SDK is **not on PATH** in this environment. Install Flutter locally before running the app, then use the commands below.

## Install Flutter

1. Download the stable SDK for Windows from [flutter.dev/docs/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows).
2. Extract to a path without spaces/admin requirements if possible (e.g. `%USERPROFILE%\dev\flutter`).
3. Add `flutter\bin` to your user `PATH`.
4. Open a new terminal and verify:

```bash
flutter --version
flutter doctor
```

Pin the documented SDK version to whatever `flutter --version` reports on this machine. Prefer that pin over global upgrades when possible.

## After install — this repo

Desktop platform folders may be missing until generated. From the project root (`dotdotdot-AI`):

```bash
flutter create . --platforms=windows,macos,linux
flutter pub get
```

`flutter create .` adds missing platform shells without wiping existing `lib/` / `pubspec.yaml` when run carefully in an already-initialized package. Prefer this once Flutter is available; earlier bootstrap may also copy shells from another project.

## Run targets

```bash
flutter run -d chrome
flutter run -d windows
```

Also valid once device tooling is ready: Android / iOS / macOS / Linux as listed by `flutter devices`.

## Notes

- `flutter pub get` needs network for pub.dev; if blocked, document an offline vendor approach.
- Dart MCP may be unavailable here — use CLI `flutter analyze` / `flutter test` when the SDK is installed.
- See [ARCHITECTURE.md](ARCHITECTURE.md) and [PLAN.md](PLAN.md) for app design.
