# Release checklist — DotDotDot AI

Use this before shipping a store/web build. Run `flutter create . --platforms=windows,macos,linux` once if desktop folders are missing (see `windows/README.md`).

## Shared (all platforms)

- [ ] `flutter analyze` clean (or only accepted infos)
- [ ] `flutter test` green
- [ ] No API keys / secrets in source, logs, or committed configs
- [ ] Version bumped in `pubspec.yaml` (`version: x.y.z+build`)
- [ ] App display name shows **DotDotDot** / **DotDotDot AI** where expected
- [ ] Model catalog asset loads; Settings can add/remove BYOK providers
- [ ] Smoke: create chat, send message (with a real key), open Projects/Plans

## Android

- [ ] `applicationId` / namespace is `com.dotdotdot.ai`
- [ ] `AndroidManifest` `android:label` is DotDotDot
- [ ] Release signing configured (not debug keys) for store builds
- [ ] `flutter build apk` or `flutter build appbundle` succeeds
- [ ] Install on a device/emulator; cold start + offline local DB works
- [ ] Internet permission present; network calls only to configured providers

## iOS

- [ ] `PRODUCT_BUNDLE_IDENTIFIER` is `com.dotdotdot.ai` (tests: `com.dotdotdot.ai.RunnerTests`)
- [ ] `CFBundleDisplayName` = DotDotDot; `CFBundleName` = `dotdotdot_ai`
- [ ] Signing & capabilities set in Xcode for the target team
- [ ] `flutter build ios` (or archive via Xcode) succeeds
- [ ] Smoke on simulator/device; secure storage survives relaunch

## Web

- [ ] `web/index.html` / `web/manifest.json` title/name = DotDotDot AI
- [ ] `flutter build web` succeeds
- [ ] Hosted under correct base href if not at domain root
- [ ] Sembast web persistence / encrypted fallback note understood for the deploy target
- [ ] Smoke in Chrome: chat list, settings, catalog

## Windows (after `flutter create`)

- [ ] Desktop folder generated; `flutter run -d windows` works
- [ ] `flutter build windows` succeeds
- [ ] App icon / window title acceptable for release
- [ ] File/media paths under app documents work on a clean machine
- [ ] Optional: code signing / MSIX packaging if distributing outside sideload

## macOS / Linux (optional)

- [ ] Generated via `flutter create . --platforms=macos,linux`
- [ ] `flutter build macos` / `flutter build linux` as needed
- [ ] Entitlements / sandbox notes reviewed for network + secure storage
