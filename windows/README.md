# Desktop platforms (Windows / macOS / Linux)

Runners are generated. From the project root, with Flutter on PATH:

```bash
flutter pub get
flutter run -d windows
# or: flutter run -d macos
# or: flutter run -d linux
```

Release binaries do **not** need administrator/root if you run them from a user-writable folder (portable). An installer that writes to `Program Files` or `/Applications` would need elevation; this project ships no such installer.

See the root [README](../README.md) deploy section.
