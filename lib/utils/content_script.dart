import 'dart:convert';

import '../models/app_settings.dart';

/// Injected into the YouTube WebView — adapted from the Chrome extension content.js.
class ContentScript {
  static const bridgeName = 'AutoNextPro';

  static String buildInjection(AppSettings settings) {
    final settingsJson = jsonEncode(settings.toJson());
    return '''
(function() {
  if (window.__autoNextProInitialized) {
    window.__autoNextProSettings = $settingsJson;
    return;
  }
  window.__autoNextProInitialized = true;

  let settings = $settingsJson;
  let hasTriggeredForCurrent = false;
  let currentVideoElement = null;
  let currentVideoUrl = "";
  const sessionStartTime = Date.now();

  window.__autoNextProSettings = settings;

  function post(type, payload) {
    if (window.$bridgeName && window.$bridgeName.postMessage) {
      window.$bridgeName.postMessage(JSON.stringify({ type: type, ...payload }));
    }
  }

  function log() {
    if (settings.loggingEnabled) {
      post('LOG', { text: Array.from(arguments).join(' ') });
    }
  }

  function refreshSettings() {
    if (window.__autoNextProSettings) {
      settings = window.__autoNextProSettings;
    }
  }

  function getActiveVideo() {
    const renderers = document.querySelectorAll("ytd-reel-video-renderer");
    for (const renderer of renderers) {
      if (renderer.hasAttribute("is-active") || renderer.classList.contains("is-active") || renderer.getAttribute("aria-hidden") === "false") {
        const video = renderer.querySelector("video");
        if (video) return video;
      }
    }
    const videos = document.querySelectorAll("video");
    for (const video of videos) {
      if (video.offsetWidth > 0 && video.offsetHeight > 0 && !video.paused) {
        return video;
      }
    }
    for (const video of videos) {
      if (video.offsetWidth > 0 && video.offsetHeight > 0) {
        return video;
      }
    }
    return null;
  }

  function attachVideoListeners(video) {
    if (video.dataset.autoNextListeners) return;
    video.dataset.autoNextListeners = "true";
    log("Hooking new video player element.");

    video.addEventListener("timeupdate", () => {
      refreshSettings();
      if (!settings.enabled || hasTriggeredForCurrent) return;
      const duration = video.duration;
      const currentTime = video.currentTime;
      if (!duration || isNaN(duration)) return;

      if (settings.skipLongVideos !== "disabled") {
        const skipLimit = parseFloat(settings.skipLongVideos);
        if (duration > skipLimit) {
          log("Skipping long video:", duration);
          triggerNavigation("skip");
          return;
        }
      }

      if (duration - currentTime <= 0.3) {
        log("Video completed playback.");
        triggerNavigation("watch");
      }
    });

    video.addEventListener("ended", () => {
      refreshSettings();
      if (!settings.enabled || hasTriggeredForCurrent) return;
      log("Video playback ended naturally.");
      triggerNavigation("watch");
    });

    video.addEventListener("seeked", () => {
      if (hasTriggeredForCurrent && video.currentTime < video.duration * 0.8) {
        hasTriggeredForCurrent = false;
      }
    });
  }

  async function triggerNavigation(type) {
    refreshSettings();
    if (hasTriggeredForCurrent) return;
    hasTriggeredForCurrent = true;
    log("Triggering auto next:", type);

    const secondsPlayed = currentVideoElement && !isNaN(currentVideoElement.duration)
      ? (currentVideoElement.currentTime || currentVideoElement.duration)
      : 0;

    post('UPDATE_STATS', {
      payload: { type: type, secondsPlayed: secondsPlayed }
    });

    if (settings.notificationsEnabled) {
      post('SHOW_NOTIFICATION', {
        text: type === "skip"
          ? "Skipped a long Short video!"
          : "Playback finished. Advancing to next Short."
      });
    }

    let delayMs = 0;
    if (type === "watch") {
      const configuredDelay = settings.delay === "custom"
        ? parseFloat(settings.customDelay)
        : parseFloat(settings.delay);
      delayMs = isNaN(configuredDelay) ? 0 : configuredDelay * 1000;
      if (settings.randomDelay && delayMs > 0) {
        delayMs += Math.random() * 1500;
      }
    }

    if (delayMs > 0) {
      await new Promise((resolve) => setTimeout(resolve, delayMs));
    }

    let success = false;
    const methods = settings.navigationPriority || ["keyboard", "button", "scroll"];
    const maxRetries = settings.maxRetries || 3;

    for (const method of methods) {
      for (let attempt = 1; attempt <= maxRetries; attempt++) {
        if (method === "keyboard") success = dispatchArrowDown();
        else if (method === "button") success = clickNextButton();
        else if (method === "scroll") success = smoothScroll();
        if (success) break;
        await new Promise((resolve) => setTimeout(resolve, 300));
      }
      if (success) break;
    }

    if (!success) smoothScroll();
  }

  function dispatchArrowDown() {
    const event = new KeyboardEvent("keydown", {
      key: "ArrowDown", code: "ArrowDown", keyCode: 40, which: 40,
      bubbles: true, cancelable: true
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
            document.querySelector('button[aria-label="Next"]');
    }
    if (btn) { btn.click(); return true; }
    return false;
  }

  function smoothScroll() {
    const activeRenderer = document.querySelector("ytd-reel-video-renderer[is-active]");
    const behavior = settings.animationEnabled ? "smooth" : "auto";
    if (activeRenderer) {
      const nextRenderer = activeRenderer.nextElementSibling;
      if (nextRenderer && nextRenderer.tagName.toLowerCase() === "ytd-reel-video-renderer") {
        nextRenderer.scrollIntoView({ behavior: behavior, block: "start" });
        return true;
      }
    }
    const shortsContainer = document.getElementById("shorts-container") || document.querySelector("ytd-shorts");
    if (shortsContainer) {
      shortsContainer.scrollBy({ top: window.innerHeight, behavior: behavior });
      return true;
    }
    window.scrollBy({ top: window.innerHeight, behavior: behavior });
    return true;
  }

  let videoTrackingInterval = setInterval(() => {
    refreshSettings();
    if (!settings.enabled) return;
    if (window.location.href !== currentVideoUrl) {
      currentVideoUrl = window.location.href;
      hasTriggeredForCurrent = false;
    }
    const activeVideo = getActiveVideo();
    if (activeVideo && activeVideo !== currentVideoElement) {
      currentVideoElement = activeVideo;
      hasTriggeredForCurrent = false;
      attachVideoListeners(activeVideo);
    }
  }, 500);

  const mutationObserver = new MutationObserver((mutations) => {
    refreshSettings();
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

  log("Auto Next Pro mobile script initialized.");
})();
''';
  }

  static String updateSettings(AppSettings settings) {
    final settingsJson = jsonEncode(settings.toJson());
    return 'window.__autoNextProSettings = $settingsJson;';
  }
}
