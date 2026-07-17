/**
 * YouTube Shorts Auto Next Pro - Content Script
 * Injected on YouTube pages to handle automatic Shorts playback progression
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
  notificationsEnabled: false
};

let settings = { ...DEFAULT_SETTINGS };
let hasTriggeredForCurrent = false;
let currentVideoElement = null;
let currentVideoUrl = "";
let sessionStartTime = Date.now();

// Logging Helper
function log(...args) {
  if (settings.loggingEnabled) {
    console.log("[Auto Next Pro]", ...args);
  }
}

// Load Settings
async function loadSettings() {
  return new Promise((resolve) => {
    chrome.storage.sync.get(DEFAULT_SETTINGS, (items) => {
      settings = { ...settings, ...items };
      log("Settings loaded:", settings);
      resolve();
    });
  });
}

// Monitor Settings Changes
chrome.storage.onChanged.addListener((changes, area) => {
  if (area === "sync") {
    for (let key in changes) {
      settings[key] = changes[key].newValue;
    }
    log("Settings updated:", settings);
    if (settings.enabled) {
      updateBadge();
    } else {
      chrome.runtime.sendMessage({ type: "UPDATE_BADGE", enabled: false });
    }
  }
});

function updateBadge() {
  chrome.runtime.sendMessage({ type: "UPDATE_BADGE", enabled: settings.enabled });
}

// Get Currently Visible and Playing Video in Shorts Reel
function getActiveVideo() {
  const renderers = document.querySelectorAll("ytd-reel-video-renderer");
  
  // Method 1: Look for YouTube's marked active renderer container
  for (const renderer of renderers) {
    if (renderer.hasAttribute("is-active") || renderer.classList.contains("is-active") || renderer.getAttribute("aria-hidden") === "false") {
      const video = renderer.querySelector("video");
      if (video) return video;
    }
  }
  
  // Method 2: Fallback to any visible playing video
  const videos = document.querySelectorAll("video");
  for (const video of videos) {
    if (video.offsetWidth > 0 && video.offsetHeight > 0 && !video.paused) {
      return video;
    }
  }

  // Method 3: Ultimate fallback, first visible video
  for (const video of videos) {
    if (video.offsetWidth > 0 && video.offsetHeight > 0) {
      return video;
    }
  }
  
  return null;
}

// Attach Event Listeners to Video Elements
function attachVideoListeners(video) {
  if (video.dataset.autoNextListeners) {
    return;
  }
  
  video.dataset.autoNextListeners = "true";
  log("Hooking new video player element.");
  
  video.addEventListener("timeupdate", () => {
    if (!settings.enabled || hasTriggeredForCurrent) return;
    
    const duration = video.duration;
    const currentTime = video.currentTime;
    
    if (!duration || isNaN(duration)) return;
    
    // Skip Long Videos Check
    if (settings.skipLongVideos !== "disabled") {
      const skipLimit = parseFloat(settings.skipLongVideos);
      if (duration > skipLimit) {
        log(`Skipping: Duration (${duration.toFixed(1)}s) exceeds limit (${skipLimit}s).`);
        triggerNavigation("skip");
        return;
      }
    }

    // Playback Complete Check
    // If we're within 0.3s of completion, auto-advance
    if (duration - currentTime <= 0.3) {
      log(`Video completed playback (${currentTime.toFixed(1)}s/${duration.toFixed(1)}s).`);
      triggerNavigation("watch");
    }
  });
  
  video.addEventListener("ended", () => {
    if (!settings.enabled || hasTriggeredForCurrent) return;
    log("Video playback ended naturally.");
    triggerNavigation("watch");
  });

  video.addEventListener("seeked", () => {
    // If user rewinds video manually, reset the trigger
    if (hasTriggeredForCurrent && video.currentTime < video.duration * 0.8) {
      log("User wound back video. Resetting progression trigger.");
      hasTriggeredForCurrent = false;
    }
  });
}

// Trigger Navigation to Next Short
async function triggerNavigation(type) {
  if (hasTriggeredForCurrent) return;
  hasTriggeredForCurrent = true;

  log(`Triggering auto next progression: ${type}`);
  
  // Update local statistics
  await updateStatistics(type);

  // Send desktop notification if enabled
  if (settings.notificationsEnabled) {
    chrome.runtime.sendMessage({
      type: "SHOW_NOTIFICATION",
      text: type === "skip" ? "Skipped a long Short video!" : "Playback finished. Advancing to next Short."
    });
  }

  // Apply Configured Delay
  let delayMs = 0;
  if (type === "watch") {
    const configuredDelay = settings.delay === "custom" ? parseFloat(settings.customDelay) : parseFloat(settings.delay);
    delayMs = isNaN(configuredDelay) ? 0 : configuredDelay * 1000;

    if (settings.randomDelay && delayMs > 0) {
      // Add random variation up to 1.5 seconds
      const randomAdd = Math.random() * 1500;
      delayMs += randomAdd;
      log(`Delaying progression for ${(delayMs / 1000).toFixed(2)}s (Randomized).`);
    } else if (delayMs > 0) {
      log(`Delaying progression for ${(delayMs / 1000).toFixed(2)}s.`);
    }
  }

  if (delayMs > 0) {
    await new Promise((resolve) => setTimeout(resolve, delayMs));
  }

  // Run Navigation Sequence
  let success = false;
  const methods = settings.navigationPriority || ["keyboard", "button", "scroll"];
  
  for (const method of methods) {
    for (let attempt = 1; attempt <= (settings.maxRetries || 3); attempt++) {
      log(`Running method "${method}" (Attempt ${attempt}/${settings.maxRetries}).`);
      
      if (method === "keyboard") {
        success = await dispatchArrowDown();
      } else if (method === "button") {
        success = await clickNextButton();
      } else if (method === "scroll") {
        success = await smoothScroll();
      }

      if (success) {
        log(`Advanced successfully via "${method}".`);
        break;
      }
      
      await new Promise((resolve) => setTimeout(resolve, 300));
    }
    if (success) break;
  }

  if (!success) {
    log("All standard navigation channels failed. Engaging ultimate scroll fallback.");
    smoothScroll();
  }
}

// Navigation Method 1: Keyboard Event
function dispatchArrowDown() {
  const event = new KeyboardEvent("keydown", {
    key: "ArrowDown",
    code: "ArrowDown",
    keyCode: 40,
    which: 40,
    bubbles: true,
    cancelable: true
  });
  
  const activeRenderer = document.querySelector("ytd-reel-video-renderer[is-active]");
  if (activeRenderer) {
    activeRenderer.dispatchEvent(event);
    window.dispatchEvent(event);
    return true;
  }
  
  document.dispatchEvent(event);
  window.dispatchEvent(event);
  return true;
}

// Navigation Method 2: Click DOM Button
function clickNextButton() {
  const activeRenderer = document.querySelector("ytd-reel-video-renderer[is-active]");
  let btn = null;
  if (activeRenderer) {
    btn = activeRenderer.querySelector("#navigation-button-down button") ||
          activeRenderer.querySelector('[aria-label="Next video"]') ||
          activeRenderer.querySelector(".navigation-button.down button");
  }
  if (!btn) {
    btn = document.querySelector("#navigation-button-down button") ||
          document.querySelector('[aria-label="Next video"]') ||
          document.querySelector("button[aria-label=\"Next\"]");
  }
  
  if (btn) {
    btn.click();
    return true;
  }
  return false;
}

// Navigation Method 3: Viewport Scrolling
function smoothScroll() {
  const activeRenderer = document.querySelector("ytd-reel-video-renderer[is-active]");
  if (activeRenderer) {
    const nextRenderer = activeRenderer.nextElementSibling;
    if (nextRenderer && nextRenderer.tagName.toLowerCase() === "ytd-reel-video-renderer") {
      nextRenderer.scrollIntoView({ behavior: settings.animationEnabled ? "smooth" : "auto", block: "start" });
      return true;
    }
  }
  
  const shortsContainer = document.getElementById("shorts-container") || document.querySelector("ytd-shorts");
  if (shortsContainer) {
    shortsContainer.scrollBy({ top: window.innerHeight, behavior: settings.animationEnabled ? "smooth" : "auto" });
    return true;
  }
  
  window.scrollBy({ top: window.innerHeight, behavior: settings.animationEnabled ? "smooth" : "auto" });
  return true;
}

// Update Local Chrome Stats
async function updateStatistics(type) {
  return new Promise((resolve) => {
    const today = new Date().toISOString().split("T")[0];
    
    chrome.storage.local.get({
      watchedCount: 0,
      skippedCount: 0,
      sessionDuration: 0,
      averageWatchTime: 0,
      totalWatchedSeconds: 0,
      date: today
    }, (stats) => {
      // Daily reset
      if (stats.date !== today) {
        stats.watchedCount = 0;
        stats.skippedCount = 0;
        stats.sessionDuration = 0;
        stats.averageWatchTime = 0;
        stats.totalWatchedSeconds = 0;
        stats.date = today;
      }

      if (type === "watch") {
        stats.watchedCount += 1;
        if (currentVideoElement && !isNaN(currentVideoElement.duration)) {
          const secondsPlayed = currentVideoElement.currentTime || currentVideoElement.duration;
          stats.totalWatchedSeconds += secondsPlayed;
          stats.averageWatchTime = Math.round(stats.totalWatchedSeconds / stats.watchedCount);
        }
      } else if (type === "skip") {
        stats.skippedCount += 1;
      }
      
      const sessionDurationMinutes = Math.round((Date.now() - sessionStartTime) / 60000);
      stats.sessionDuration = sessionDurationMinutes;

      chrome.storage.local.set(stats, () => {
        log("Stats persisted:", stats);
        resolve();
      });
    });
  });
}

// Continuous Loop to Identify Playing Video Elements
let videoTrackingInterval = null;
function setupVideoTracking() {
  if (videoTrackingInterval) clearInterval(videoTrackingInterval);
  
  videoTrackingInterval = setInterval(() => {
    if (!settings.enabled) return;
    
    // Check for SPA route modifications
    if (window.location.href !== currentVideoUrl) {
      currentVideoUrl = window.location.href;
      hasTriggeredForCurrent = false;
      log("Path transition detected:", currentVideoUrl);
    }
    
    const activeVideo = getActiveVideo();
    if (activeVideo && activeVideo !== currentVideoElement) {
      currentVideoElement = activeVideo;
      hasTriggeredForCurrent = false;
      attachVideoListeners(activeVideo);
    }
  }, 500);
}

// Main Initialization
async function init() {
  log("Starting content scripts...");
  await loadSettings();
  updateBadge();
  setupVideoTracking();
  
  // Set up MutationObserver as real-time attachment channel
  const mutationObserver = new MutationObserver((mutations) => {
    if (!settings.enabled) return;
    for (const mutation of mutations) {
      if (mutation.type === "attributes" && mutation.attributeName === "is-active") {
        const target = mutation.target;
        if (target.hasAttribute("is-active")) {
          const video = target.querySelector("video");
          if (video) {
            currentVideoElement = video;
            hasTriggeredForCurrent = false;
            attachVideoListeners(video);
          }
        }
      }
    }
  });

  mutationObserver.observe(document.body, {
    attributes: true,
    subtree: true,
    attributeFilter: ["is-active", "active", "aria-hidden"]
  });
}

// Check if document loaded
if (document.readyState === "loading") {
  document.addEventListener("DOMContentLoaded", init);
} else {
  init();
}