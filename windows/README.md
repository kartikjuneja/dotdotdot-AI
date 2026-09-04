# Desktop platforms (Windows / macOS / Linux)

This environment had no Flutter SDK on PATH, and the `project-finance` shell only included Android, iOS, and Web.

After installing Flutter, generate the missing desktop runners from the project root:

```bash
flutter create . --platforms=windows,macos,linux
flutter pub get
flutter run -d windows
```

Do not overwrite `lib/`, `pubspec.yaml`, or `docs/`.
