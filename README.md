# DotDotDot AI

Local-first Flutter AI studio: bring your own API keys (OpenAI, Gemini, OpenRouter), chat and generate media, organize work into **projects** and nested **plans/courses**, with scoped memory/context and optional **Google Drive** sync.

## Platforms

Android, iOS, Web, Windows, macOS, and Linux runners are in the repo.

```bash
flutter pub get
flutter run -d chrome      # web
flutter run -d windows     # desktop
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

## Deploy (personal use)

This app is **local-first / BYOK**. There is no backend to host. You host the Flutter **web** build as static files, or run a **desktop/mobile** binary on your machine.

### GitHub Pages (recommended free web host)

Yes — you can build with GitHub Actions and host on GitHub Pages. This repo includes `.github/workflows/ci.yml` which:

1. Runs `flutter analyze` + `flutter test`
2. Builds `flutter build web --release --base-href /<repo>/`
3. Deploys to GitHub Pages on pushes to `main`

Enable Pages once: repo **Settings → Pages → Source: GitHub Actions**. After the first green `main` run the app is at:

`https://<user>.github.io/<repo>/`

Routes use hash URLs (`/#/settings`) so GitHub Pages does not need rewrite rules.

**Web caveats for personal use**

- API keys live in the browser (weaker than OS keychain). Prefer desktop for long-lived keys.
- OpenAI’s HTTP API often **blocks browser CORS**. OpenRouter is the practical web provider; Gemini may work depending on Google’s CORS headers.
- Google Drive cloud sync needs OAuth client IDs. Until then, Settings uses a **local encrypted mirror**, not Drive.

### Other static web hosts

Same `build/web` folder works on **Cloudflare Pages**, **Netlify**, **Firebase Hosting**, **Render Static Site**, **Vercel** (static), or any nginx/CDN. Set `--base-href /` if the app is at the domain root. Path-based hosts that rewrite unknown URLs to `index.html` can drop hash URLs later.

### Desktop (Windows / macOS / Linux)

Does **not** need admin rights if you run a portable build from your user folder:

```bash
flutter create . --platforms=windows,macos,linux
flutter pub get
flutter build windows   # or macos / linux
```

Copy `build/windows/x64/runner/Release/` (or the macOS `.app` / Linux bundle) somewhere under your home directory and run the executable. Admin is only required if an installer writes to `Program Files` / `/Applications` system-wide, which this project does not do.

### Android APK (sideload)

`flutter build apk` then install the APK. No Play Store or admin PC rights required; Android may ask you to allow unknown sources.

### iOS

Needs a Mac + Apple Developer signing. Not required for personal Windows/Web use.
