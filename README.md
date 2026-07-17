# YouTube Shorts Auto Next Pro — Mobile

Flutter mobile app port of **YouTube Shorts Auto Next Pro**. It mirrors the Chrome extension feature set: auto-advance after each Short finishes, customizable delays, skip-long-video rules, statistics, navigation priority, and backup/restore.

The Chrome extension lives on the `main` branch. This `mobile` branch contains the Flutter app only.

---

## Features

- **Auto-next progression** — Injects the same content-script logic into a YouTube Shorts WebView
- **Quick settings sheet** — Enable/disable, delay, skip-long-videos, random delay (popup equivalent)
- **Advanced settings** — Theme, notifications, debug logging, navigation priority, retries, import/export
- **Daily statistics** — Watched, skipped, session duration, average watch time (resets daily)
- **Local notifications** — Optional alerts when auto-advancing

---

## Requirements

- Flutter 3.41+ (stable)
- Xcode (iOS) or Android Studio / SDK (Android)
- Physical device or emulator with network access

---

## Getting Started

```bash
# Checkout the mobile branch
git checkout mobile

# Install dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

---

## Project Structure

```text
lib/
├── main.dart                      # App entry + theme wiring
├── models/
│   ├── app_settings.dart          # Settings model (chrome.storage.sync equivalent)
│   └── watch_stats.dart           # Daily metrics (chrome.storage.local equivalent)
├── services/
│   ├── app_state.dart             # SharedPreferences persistence + JS bridge handler
│   └── notification_service.dart  # Local notifications
├── screens/
│   ├── home_screen.dart           # Full-screen YouTube Shorts WebView
│   ├── quick_settings_sheet.dart  # Popup-equivalent bottom sheet
│   └── advanced_settings_screen.dart  # Options-equivalent panel
├── theme/
│   └── app_theme.dart             # Slate dark theme matching the extension
└── utils/
    └── content_script.dart        # Adapted content.js for WebView injection
```

---

## How It Works

1. The app loads `https://www.youtube.com/shorts` in a WebView with a mobile Chrome user agent.
2. On page load, `content_script.dart` injects JavaScript adapted from the extension's `content.js`.
3. Settings are pushed from Flutter via `window.__autoNextProSettings`.
4. The script reports stats and notification requests back through a JavaScript channel (`AutoNextPro`).

---

## Platform Notes

- **Android**: Requires `INTERNET` and `POST_NOTIFICATIONS` (Android 13+).
- **iOS**: Web content loads over HTTPS; sign in to YouTube in the WebView if needed.
- YouTube may change DOM selectors over time — the navigation priority fallbacks (keyboard → button → scroll) match the extension behavior.

---

## Related

- Chrome extension: `main` branch
- Architecture reference: `RECONSTRUCTION_SUMMARY.md` (on `main`)
