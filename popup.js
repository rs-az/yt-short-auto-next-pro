/**
 * YouTube Shorts Auto Next Pro - Popup Script
 * Connects UI widgets to chrome.storage
 */

const DEFAULT_SETTINGS = {
  enabled: true,
  delay: 0,
  customDelay: 0,
  skipLongVideos: "disabled",
  randomDelay: false
};

document.addEventListener("DOMContentLoaded", async () => {
  // Elements
  const enabledToggle = document.getElementById("enabled-toggle");
  const delaySelect = document.getElementById("delay-select");
  const customDelayGroup = document.getElementById("custom-delay-group");
  const customDelayInput = document.getElementById("custom-delay-input");
  const skipSelect = document.getElementById("skip-select");
  const randomDelayCheckbox = document.getElementById("random-delay-checkbox");
  
  const statusBanner = document.getElementById("status-banner");
  const statusText = document.getElementById("status-text");
  
  const statWatched = document.getElementById("stat-watched");
  const statSkipped = document.getElementById("stat-skipped");
  const statDuration = document.getElementById("stat-duration");
  const statAvgTime = document.getElementById("stat-avg-time");
  
  const resetStatsBtn = document.getElementById("reset-stats-btn");
  const openSettingsBtn = document.getElementById("open-settings-btn");
  const githubLink = document.getElementById("github-link");

  // Load settings and update UI
  chrome.storage.sync.get(DEFAULT_SETTINGS, (settings) => {
    enabledToggle.checked = settings.enabled;
    delaySelect.value = settings.delay;
    customDelayInput.value = settings.customDelay;
    skipSelect.value = settings.skipLongVideos;
    randomDelayCheckbox.checked = settings.randomDelay;

    // Custom delay field visibility
    toggleCustomDelayVisibility(settings.delay === "custom");
    
    // Status banner state
    updateStatusBanner(settings.enabled);
  });

  // Load stats and update UI
  loadStats();

  // Settings Change Listeners
  enabledToggle.addEventListener("change", (e) => {
    const enabled = e.target.checked;
    chrome.storage.sync.set({ enabled });
    updateStatusBanner(enabled);
    
    // Send message to update badge
    chrome.runtime.sendMessage({ type: "UPDATE_BADGE", enabled });
  });

  delaySelect.addEventListener("change", (e) => {
    const delay = e.target.value;
    chrome.storage.sync.set({ delay });
    toggleCustomDelayVisibility(delay === "custom");
  });

  customDelayInput.addEventListener("change", (e) => {
    const customDelay = parseFloat(e.target.value) || 0;
    chrome.storage.sync.set({ customDelay });
  });

  skipSelect.addEventListener("change", (e) => {
    const skipLongVideos = e.target.value;
    chrome.storage.sync.set({ skipLongVideos });
  });

  randomDelayCheckbox.addEventListener("change", (e) => {
    const randomDelay = e.target.checked;
    chrome.storage.sync.set({ randomDelay });
  });

  // Open Options Page
  openSettingsBtn.addEventListener("click", () => {
    if (chrome.runtime.openOptionsPage) {
      chrome.runtime.openOptionsPage();
    } else {
      window.open(chrome.runtime.getURL("options.html"));
    }
  });

  // Reset Stats Button
  resetStatsBtn.addEventListener("click", () => {
    if (confirm("Are you sure you want to reset today's statistics?")) {
      const today = new Date().toISOString().split("T")[0];
      chrome.storage.local.set({
        watchedCount: 0,
        skippedCount: 0,
        sessionDuration: 0,
        averageWatchTime: 0,
        totalWatchedSeconds: 0,
        date: today
      }, () => {
        loadStats();
      });
    }
  });

  // Set github URL placeholder
  githubLink.href = "https://github.com/placeholder/youtube-shorts-auto-next-pro";

  // Helpers
  function toggleCustomDelayVisibility(visible) {
    if (visible) {
      customDelayGroup.classList.remove("hidden");
    } else {
      customDelayGroup.classList.add("hidden");
    }
  }

  function updateStatusBanner(enabled) {
    if (enabled) {
      statusBanner.classList.remove("disabled");
      statusText.textContent = "Auto Next is Active";
    } else {
      statusBanner.classList.add("disabled");
      statusText.textContent = "Auto Next is Paused";
    }
  }

  function loadStats() {
    chrome.storage.local.get({
      watchedCount: 0,
      skippedCount: 0,
      sessionDuration: 0,
      averageWatchTime: 0
    }, (stats) => {
      statWatched.textContent = stats.watchedCount;
      statSkipped.textContent = stats.skippedCount;
      statDuration.textContent = stats.sessionDuration + "m";
      statAvgTime.textContent = stats.averageWatchTime + "s";
    });
  }
});