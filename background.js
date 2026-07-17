/**
 * YouTube Shorts Auto Next Pro - Background Script
 * Manifest V3 Service Worker
 */

const DEFAULT_SETTINGS = {
  enabled: true,
  delay: 0,
  customDelay: 0,
  skipLongVideos: "disabled",
  randomDelay: false,
  navigationPriority: ["keyboard", "button", "scroll"],
  maxRetries: 3,
  loggingEnabled: true,
  animationEnabled: true,
  notificationsEnabled: false,
  theme: "system"
};

const DEFAULT_STATS = {
  watchedCount: 0,
  skippedCount: 0,
  sessionDuration: 0,
  averageWatchTime: 0,
  totalWatchedSeconds: 0,
  date: new Date().toISOString().split("T")[0]
};

// On Installation
chrome.runtime.onInstalled.addListener((details) => {
  console.log("[Auto Next Pro] Extension installed or updated!");
  
  // Initialize settings
  chrome.storage.sync.get(null, (existingSettings) => {
    const newSettings = { ...DEFAULT_SETTINGS, ...existingSettings };
    chrome.storage.sync.set(newSettings, () => {
      console.log("[Auto Next Pro] Default settings initialized:", newSettings);
    });
  });

  // Initialize stats
  chrome.storage.local.get(null, (existingStats) => {
    const today = new Date().toISOString().split("T")[0];
    const newStats = { ...DEFAULT_STATS, ...existingStats, date: today };
    chrome.storage.local.set(newStats, () => {
      console.log("[Auto Next Pro] Default statistics initialized:", newStats);
    });
  });

  // Update initial badge
  updateBadge(DEFAULT_SETTINGS.enabled);
});

// Message Listener
chrome.runtime.onMessage.addListener((message, sender, sendResponse) => {
  if (message.type === "UPDATE_BADGE") {
    updateBadge(message.enabled);
  } else if (message.type === "SHOW_NOTIFICATION") {
    chrome.notifications.create({
      type: "basic",
      iconUrl: "icons/128.png",
      title: "YouTube Shorts Auto Next Pro",
      message: message.text,
      priority: 1
    });
  }
});

// Helper to update badge
function updateBadge(enabled) {
  const text = enabled ? "ON" : "OFF";
  const color = enabled ? "#10B981" : "#6B7280"; // Emerald green vs slate gray
  
  chrome.action.setBadgeText({ text });
  chrome.action.setBadgeBackgroundColor({ color });
}

// Alarm/Daily Reset check on startup
chrome.runtime.onStartup.addListener(() => {
  checkDailyReset();
});

function checkDailyReset() {
  const today = new Date().toISOString().split("T")[0];
  chrome.storage.local.get(["date"], (result) => {
    if (result.date && result.date !== today) {
      console.log("[Auto Next Pro] Day changed. Resetting daily statistics...");
      chrome.storage.local.set({
        watchedCount: 0,
        skippedCount: 0,
        sessionDuration: 0,
        averageWatchTime: 0,
        totalWatchedSeconds: 0,
        date: today
      });
    }
  });
}