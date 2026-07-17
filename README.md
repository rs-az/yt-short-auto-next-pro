# yt-short-auto-next-pro# YouTube Shorts Auto Next Pro

**YouTube Shorts Auto Next Pro** is a modern, lightweight, highly optimized Google Chrome Extension (Manifest V3) that automatically advances to the next YouTube Short after the current Short finishes playing once. 

It is designed with robustness and user control in mind—offering customizable delays, smart skip criteria for long videos, statistics tracking, randomized behavior, custom theme options, and more, all without leaking memory or causing high CPU overhead.

---

## Features

- **⏱️ Auto-Next Progression**: Automatically scroll or advance to the next Short when the current video finishes.
- **🕒 Customizable Delays**: Configure a waiting buffer of 0s, 1s, 2s, 3s, 5s, or define your own custom value in seconds.
- **🎲 Natural Human Behavior (Random Delay)**: Add minor random variance (0 to 1.5 seconds) to your delays to simulate human interactions.
- **✂️ Skip Long Videos**: Instantly skip Shorts that are longer than a specified cutoff (30s, 45s, 60s, 90s) so your feed stays quick and relevant.
- **📊 Metric Tracking**: Live metrics for videos watched, videos skipped, session durations, and average watch times, automatically reset daily.
- **🛡️ Robust Playback Detection**: Hooks directly into HTML5 `<video>` state changes rather than relying on heavy, resource-intensive polling loops.
- **🎹 Fail-Safe Navigation Priority**: Custom priority arrays between arrow-down keystrokes, HTML click selectors, or viewport smooth scroll commands.
- **🎨 Custom options UI**: Complete settings panel with Dark, Light, or automatic System preference theme syncing.

---

## Installation & Developer Mode Guide

Since the extension is production-ready but unpacked, you can install it into Google Chrome in seconds:

1. **Download the Extension Files**: Download or clone this folder containing all source files (e.g., `manifest.json`, `content.js`, etc.) to your local computer.
2. **Open Chrome Extensions**: In your Google Chrome browser, navigate to:
   ```text
   chrome://extensions/
   ```
3. **Enable Developer Mode**: In the upper-right corner of the Extensions page, click the toggle switch to enable **Developer Mode**.
4. **Load Unpacked Extension**:
   - In the top-left, click the button labeled **Load unpacked**.
   - Select the directory folder containing these extension files (the one containing `manifest.json`).
5. **Success!**: The extension is now successfully installed! You will see the **YouTube Shorts Auto Next Pro** icon in your browser toolbar.

---

## Technical Details & API Permissions

To maintain complete user safety, this extension requests minimal permissions:

- `storage`: Required to save user configurations (using `chrome.storage.sync`) and store daily watch metrics (using `chrome.storage.local`).
- `notifications` *(optional)*: Used to issue a desktop alert when auto-advancing (can be enabled/disabled in settings).
- `host_permissions` (`https://www.youtube.com/*`): Necessary to inject the lightweight content script into YouTube Shorts pages to monitor video elements.

---

## Code Quality & Engineering Architecture

The extension is designed for modern chrome standard practices:
- **No Global Leakage**: JavaScript modules are wrapped and scoped to prevent namespace collisions.
- **Optimized Observers**: Uses a combined `MutationObserver` on the page layout to find newly active reel renderers instantly, rather than relying on heavy intervals.
- **Intelligent Loop Checks**: Monitors playback states continuously inside content scripts using native event listeners. If a video loops around, the wrap-around is instantly captured.

---

## Troubleshooting

- **Extension is loaded, but doesn't scroll**:
  - Refresh the YouTube tab to make sure the content script is loaded.
  - Check the popup menu to verify that the main toggle switch is set to **ON**.
  - Ensure you are viewing the vertical Shorts reel (`https://www.youtube.com/shorts/...`) instead of traditional horizontal video pages.
- **Debugging**:
  - Open the Advanced Settings panel, navigate to **General Configuration**, and turn on **Debug Console Logging**.
  - Open your browser's Developer Tools (F12 or right-click -> Inspect) on the YouTube tab to see detailed step-by-step logs from the extension.
