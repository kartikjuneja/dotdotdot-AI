# DotDotDot AI

Local-first Flutter AI studio: bring your own API keys (OpenAI, Gemini, OpenRouter), chat and generate media, organize work into **projects** and nested **plans/courses**, with scoped memory/context and optional **Google Drive** sync.

## Platforms

Android, iOS, Web are scaffolded. After installing the Flutter SDK, add desktop shells:

```bash
flutter create . --platforms=windows,macos,linux
flutter pub get
flutter run -d chrome
```

See [docs/SDK.md](docs/SDK.md) and [docs/PLAN.md](docs/PLAN.md).

## Quick start

1. Install Flutter (stable) and ensure `flutter` is on `PATH`.
2. `flutter pub get`
3. `flutter run -d windows` or `flutter run -d chrome`
4. Open **Settings**, add a provider API key, then start a chat.

## Architecture

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md). Task tracking: [docs/TASKS.md](docs/TASKS.md).

## Privacy

API keys stay in secure storage on-device. Google Drive backups exclude keys by default.
