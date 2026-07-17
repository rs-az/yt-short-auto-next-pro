/**
 * YouTube Shorts Auto Next Pro - Options Script
 * Handles advanced configuration, import/export, re-ordering, and reset tasks
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

document.addEventListener("DOMContentLoaded", () => {
  // Elements
  const themeSelect = document.getElementById("theme-select");
  const animationCheckbox = document.getElementById("animation-checkbox");
  const notificationCheckbox = document.getElementById("notification-checkbox");
  const loggingCheckbox = document.getElementById("logging-checkbox");
  const maxRetriesInput = document.getElementById("max-retries-input");
  
  const priorityList = document.getElementById("priority-list");
  const saveToast = document.getElementById("save-toast");
  
  const exportSettingsBtn = document.getElementById("export-settings-btn");
  const importSettingsFile = document.getElementById("import-settings-file");
  const factoryResetBtn = document.getElementById("factory-reset-btn");

  // Navigation Items Map
  const itemsMap = {
    keyboard: priorityList.querySelector('[data-method="keyboard"]'),
    button: priorityList.querySelector('[data-method="button"]'),
    scroll: priorityList.querySelector('[data-method="scroll"]')
  };

  // Tab Navigation Elements
  const navItems = document.querySelectorAll(".nav-item");
  const tabPanels = document.querySelectorAll(".tab-panel");

  // Tab switching
  navItems.forEach((item) => {
    item.addEventListener("click", () => {
      const tabId = item.dataset.tab;
      
      navItems.forEach((i) => i.classList.remove("active"));
      tabPanels.forEach((p) => p.classList.remove("active"));
      
      item.classList.add("active");
      document.getElementById(`tab-${tabId}`).classList.add("active");
    });
  });

  // Load Settings
  chrome.storage.sync.get(DEFAULT_SETTINGS, (settings) => {
    themeSelect.value = settings.theme;
    animationCheckbox.checked = settings.animationEnabled;
    notificationCheckbox.checked = settings.notificationsEnabled;
    loggingCheckbox.checked = settings.loggingEnabled;
    maxRetriesInput.value = settings.maxRetries;

    // Apply active theme
    applyTheme(settings.theme);

    // Render navigation priority
    renderPriority(settings.navigationPriority);
  });

  // Save Settings Changes
  const saveChanges = (changedSettings) => {
    chrome.storage.sync.set(changedSettings, () => {
      showToast();
    });
  };

  // Change Event Listeners
  themeSelect.addEventListener("change", (e) => {
    const theme = e.target.value;
    saveChanges({ theme });
    applyTheme(theme);
  });

  animationCheckbox.addEventListener("change", (e) => {
    saveChanges({ animationEnabled: e.target.checked });
  });

  notificationCheckbox.addEventListener("change", (e) => {
    saveChanges({ notificationsEnabled: e.target.checked });
  });

  loggingCheckbox.addEventListener("change", (e) => {
    saveChanges({ loggingEnabled: e.target.checked });
  });

  maxRetriesInput.addEventListener("change", (e) => {
    const maxRetries = parseInt(e.target.value) || 3;
    saveChanges({ maxRetries });
  });

  // Priority Arrange Controls
  priorityList.addEventListener("click", (e) => {
    if (e.target.classList.contains("btn-up")) {
      const item = e.target.closest(".priority-item");
      const prev = item.previousElementSibling;
      if (prev) {
        priorityList.insertBefore(item, prev);
        savePriority();
      }
    } else if (e.target.classList.contains("btn-down")) {
      const item = e.target.closest(".priority-item");
      const next = item.nextElementSibling;
      if (next) {
        priorityList.insertBefore(next, item);
        savePriority();
      }
    }
  });

  // Export Settings JSON
  exportSettingsBtn.addEventListener("click", () => {
    chrome.storage.sync.get(null, (syncData) => {
      chrome.storage.local.get(null, (localData) => {
        const backup = {
          sync: syncData,
          local: localData,
          exportedAt: new Date().toISOString()
        };
        
        const blob = new Blob([JSON.stringify(backup, null, 2)], { type: "application/json" });
        const url = URL.createObjectURL(blob);
        
        const a = document.createElement("a");
        a.href = url;
        a.download = `youtube-shorts-auto-next-backup-${new Date().toISOString().split("T")[0]}.json`;
        document.body.appendChild(a);
        a.click();
        document.body.removeChild(a);
        URL.revokeObjectURL(url);
      });
    });
  });

  // Import Settings JSON
  importSettingsFile.addEventListener("change", (e) => {
    const file = e.target.files[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (event) => {
      try {
        const backup = JSON.parse(event.target.result);
        if (backup.sync) {
          chrome.storage.sync.set(backup.sync, () => {
            if (backup.local) {
              chrome.storage.local.set(backup.local, () => {
                alert("Configuration and statistics imported successfully!");
                window.location.reload();
              });
            } else {
              alert("Settings imported successfully!");
              window.location.reload();
            }
          });
        } else {
          alert("Invalid backup file structure: missing sync settings.");
        }
      } catch (err) {
        alert("Failed to parse settings JSON. Check if file is valid.");
      }
    };
    reader.readAsText(file);
  });

  // Factory Reset
  factoryResetBtn.addEventListener("click", () => {
    if (confirm("CRITICAL ACTION: Are you sure you want to restore the extension to its factory defaults? All settings and today's statistics will be completely erased.")) {
      chrome.storage.sync.clear(() => {
        chrome.storage.local.clear(() => {
          chrome.storage.sync.set(DEFAULT_SETTINGS, () => {
            const today = new Date().toISOString().split("T")[0];
            chrome.storage.local.set({
              watchedCount: 0,
              skippedCount: 0,
              sessionDuration: 0,
              averageWatchTime: 0,
              totalWatchedSeconds: 0,
              date: today
            }, () => {
              alert("Extension restored to factory defaults successfully!");
              window.location.reload();
            });
          });
        });
      });
    }
  });

  // Helpers
  function applyTheme(theme) {
    document.body.className = ""; // Reset
    
    if (theme === "dark") {
      document.body.classList.add("dark-theme");
    } else if (theme === "light") {
      document.body.classList.add("light-theme");
    } else {
      // System Theme
      const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
      document.body.classList.add(prefersDark ? "dark-theme" : "light-theme");
    }
  }

  function renderPriority(priorityArr) {
    priorityList.innerHTML = "";
    priorityArr.forEach((method) => {
      const element = itemsMap[method];
      if (element) {
        priorityList.appendChild(element);
      }
    });
  }

  function savePriority() {
    const priorityItems = priorityList.querySelectorAll(".priority-item");
    const newPriority = Array.from(priorityItems).map((item) => item.dataset.method);
    saveChanges({ navigationPriority: newPriority });
  }

  let toastTimeout;
  function showToast() {
    saveToast.classList.add("show");
    clearTimeout(toastTimeout);
    toastTimeout = setTimeout(() => {
      saveToast.classList.remove("show");
    }, 2000);
  }
});