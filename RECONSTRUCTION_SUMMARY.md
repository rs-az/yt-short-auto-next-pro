# Reconstructive Architecture & Code Blueprint: YouTube Shorts Auto Next Pro

This document serves as a complete development report and reconstruction guide for **YouTube Shorts Auto Next Pro**. It lists all files created or modified, explains their internal mechanisms, and outlines how the visual simulator and extension assets are structured. You can provide this file to any other agent or developer to reconstruct, understand, or extend this application.

---

## 📂 Codebase Inventory

Here is the file structure established in the workspace:

```text
├── metadata.json                 # Project configuration and capabilities
├── package.json                  # React application dependencies (JSZip, Lucide React, Tailwind, Vite)
├── src/
│   ├── App.tsx                   # Master visual simulation & workspace UI dashboard
│   ├── index.css                 # Global Tailwind theme & display typography setup
│   ├── main.tsx                  # Vite React application entrypoint
│   └── extension-files.ts        # Central repository storing source code strings for the Chrome extension
└── youtube-shorts-auto-next/
    └── icons/                    # Built-in packed icon PNG assets (16x16, 48x48, 128x128)
```

---

## ⚡ 1. The React Simulator & Code Workspace (`/src/App.tsx`)

`App.tsx` serves as the developer dashboard. It links live configuration changes to a real-time simulator, visual mockups, and a source code viewer.

### Key Components & Capabilities:
* **Real-time Shorts Playback Simulator**: 
  - Simulates a mobile device running YouTube Shorts.
  - Implements an automated state tick (every 100ms) representing video playback.
  - Features real-time state listeners: checks for long videos (auto-skips based on user-defined limits) and handles completed videos.
  - Displays dynamic overlays for active countdowns, randomized delays, and vertical scroll transition animations.
* **Developer Debug Console Logs**: 
  - Captures and displays timestamped runtime events (such as tracking active players, changing routing urls, or simulating keyboard progression).
* **Extension UI Sandboxing**:
  - **Popup.html Simulation**: A pixel-perfect mockup of the extension popup with fully interactive switches, select dropdowns, custom input triggers, and active watch-time/session statistics counters.
  - **Options.html Simulation**: A multi-tab mockup containing Advanced Theme selection, Desktop notification toggles, debug console flags, and custom sorting list logic to rearrange navigation priority (e.g., swapping keyboard arrow simulation, DOM buttons, or viewport scrolling).
* **Interactive Code Workspace Explorer**:
  - A tabbed view containing the raw source code of the Chrome Extension.
  - Features quick-actions for **Copying to clipboard** and **Single-file download**.
* **ZIP Compiler (`downloadCompleteZip`)**:
  - Leverages `jszip` to bundle all extension files (including raw string mappings and binary base64 icons) into a ready-to-load package named `youtube-shorts-auto-next-pro.zip`.

---

## 🛠️ 2. Central Extension Repository (`/src/extension-files.ts`)

`extension-files.ts` is the central source of truth storing all files belonging to the final extension. When the user downloads the ZIP, the React bundle extracts these keys:

### 📄 `manifest.json`
Specifies Manifest V3 compliance:
* **Permissions**: Uses `storage` (for keeping delay metrics) and `notifications` (for desktop alerts).
* **Host Permissions**: Hooks onto `https://www.youtube.com/*`.
* **Action & Options UI**: Declares `popup.html` and `options.html` as the default entry portals.
* **Content Scripts**: Injects `content.js` to execute at `document_idle`.

### 📄 `background.js` (Service Worker)
* **Default Setup**: Initializes `chrome.storage.sync` with default settings and `chrome.storage.local` with daily metrics (watched, skipped, durations).
* **Activity Badge**: Updates the extension badge text (`ON` in emerald green vs `OFF` in slate gray) via `chrome.action.setBadgeText`.
* **Notifications Channel**: Listens to active progress messages and triggers native system desktop notification alerts.
* **Daily Reset Scheduler**: Monitors timestamps on startup and automatically purges watch stats when a calendar day flips.

### 📄 `content.js` (Content Script)
This is the core execution script injected into YouTube. It monitors media player states and simulates user progression events:
* **Active Player Hook**: Runs a 500ms heartbeat lookup paired with a `MutationObserver` looking for `is-active` and `aria-hidden` updates. This hooks into active video rendering blocks inside YouTube's single-page-application (SPA) router.
* **Time Tracking Listener**: Listens to the HTML5 video `timeupdate` and `ended` events. If the video duration exceeds limits, it launches a skip trigger. If the playback is within `0.3s` of the total length, it triggers the progression process.
* **Intelligent Progression Mechanism**:
  1. Updates sync storage metrics.
  2. Calculates user delays, adding an optional randomized 0–1.5s delay to mimic human behavior and bypass bot-detection models.
  3. Cycles through the configured **Navigation Priorities** (Keyboard key dispatch, DOM button clicks, or Smooth window scrolling) with active retries before executing ultimate viewports rollbacks.

### 📄 `popup.html / popup.js / popup.css` (Popup Controls)
* **popup.html**: Designed using a modern slate-dark layout (`#0F172A`). Contains state switches and quick-select inputs.
* **popup.js**: Syncs user updates straight to `chrome.storage.sync` (triggering instant updates inside active content scripts) and displays today's metrics.

### 📄 `options.html / options.js / options.css` (Advanced Options Panel)
* **options.html**: Responsive double-column configuration pane designed with sidebars.
* **options.js**: Integrates sub-tabs (General settings, Navigation Priorities, Data Administration). Implements dynamic list re-ordering: users click arrow controls to shuffle array hierarchies inside `chrome.storage`. Includes backup export/import buttons to save settings configurations locally as a `.json` file.

---

## 🎨 3. Typography & Styling Settings (`/src/index.css`)

Our global style files are fully integrated with Tailwind CSS, supporting:
* **Typography Pairing**: Matches **Inter** (for general settings and readouts), **Space Grotesk** (for display/branding headings), and **JetBrains Mono** (for statistics, debug lines, and code blocks).
* **Responsive Layouts**: Designed to stretch elegantly from compact viewports to large widescreen displays.

---

## 🚀 Re-compilation & Packed ZIP Assembly

When the developer or another agent launches compilation:
1. `jszip` instantiates a new virtual container on the fly.
2. The code maps out raw strings inside `/src/extension-files.ts` to their corresponding file boundaries.
3. Binary PNG assets (specifically `icons/16.png`, `icons/48.png`, and `icons/128.png`) are converted from Base64 chunks and written directly inside the `icons/` subdirectory.
4. The file structure is saved and output as a single compressed zip file.
