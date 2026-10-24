// Browser preferences, privacy acknowledgement and small accessibility helpers.

(function () {
  "use strict";

  var handlersRegistered = false;
  var initialValuesSent = false;
  var dirty = false;

  function queryParam(name) {
    try {
      return new URLSearchParams(window.location.search).get(name);
    } catch (e) {
      return null;
    }
  }

  function applyQueryTheme() {
    var theme = queryParam("theme");
    if (theme === "dark" || theme === "light") {
      document.documentElement.setAttribute("data-bs-theme", theme);
    }
  }

  function setInput(name, value) {
    if (window.Shiny && typeof window.Shiny.setInputValue === "function") {
      window.Shiny.setInputValue(name, value, { priority: "event" });
      return true;
    }
    return false;
  }

  function registerHandlers() {
    if (handlersRegistered || !window.Shiny ||
        typeof window.Shiny.addCustomMessageHandler !== "function") {
      return;
    }
    handlersRegistered = true;

    window.Shiny.addCustomMessageHandler("mcmctreer_save_lang", function (value) {
      try {
        window.localStorage.setItem("mcmctreer.lang", value);
      } catch (e) {
        // localStorage can be unavailable in private browsing; ignore.
      }
    });

    window.Shiny.addCustomMessageHandler("mcmctreer_privacy_seen", function (value) {
      try {
        window.localStorage.setItem("mcmctreer.privacy", "1");
      } catch (e) {
        // Ignore.
      }
    });

    window.Shiny.addCustomMessageHandler("mcmctreer_dirty", function (value) {
      dirty = value === true;
    });
  }

  window.addEventListener("beforeunload", function (event) {
    if (!dirty) return;
    event.preventDefault();
    event.returnValue = "Your configuration will be lost / 配置将丢失";
    return event.returnValue;
  });

  function sendInitialValues() {
    if (initialValuesSent) return;
    if (!window.Shiny || typeof window.Shiny.setInputValue !== "function") return;
    initialValuesSent = true;

    setInput("i18n-browser_lang", navigator.language || navigator.userLanguage || "en");

    var savedLang = null;
    try {
      savedLang = window.localStorage.getItem("mcmctreer.lang");
    } catch (e) {
      savedLang = null;
    }
    var requestedLang = queryParam("lang");
    if (requestedLang === "zh" || requestedLang === "en") {
      savedLang = requestedLang;
    }
    if (savedLang) setInput("i18n-lang_saved", savedLang);

    var seen = false;
    try {
      seen = window.localStorage.getItem("mcmctreer.privacy") === "1";
    } catch (e) {
      seen = false;
    }
    if (queryParam("privacy") === "1") seen = true;
    setInput("privacy_seen", seen);
  }

  function labelTopBarControls() {
    var langSelect = document.querySelector(".lang-switch select");
    if (langSelect && !langSelect.getAttribute("aria-label")) {
      langSelect.setAttribute("aria-label", "Language / 语言");
    }
    var themeSelect = document.querySelector(".theme-switch select");
    if (themeSelect && !themeSelect.getAttribute("aria-label")) {
      themeSelect.setAttribute("aria-label", "Plot colours / 绘图配色");
    }
    var themeButton = document.querySelector(".theme-switch .form-check-input");
    if (themeButton && !themeButton.getAttribute("aria-label")) {
      themeButton.setAttribute("aria-label", "Light or dark mode / 亮色或暗色模式");
    }
  }

  document.addEventListener("shiny:connected", function () {
    registerHandlers();
    applyQueryTheme();
    sendInitialValues();
    labelTopBarControls();
  });

  document.addEventListener("DOMContentLoaded", function () {
    applyQueryTheme();
    // Fallback for pages where shiny:connected fires before this listener.
    window.setTimeout(function () {
      registerHandlers();
      applyQueryTheme();
      sendInitialValues();
      labelTopBarControls();
    }, 400);
  });

  document.addEventListener("shiny:value", function () {
    window.setTimeout(labelTopBarControls, 0);
  });

  document.addEventListener("click", function () {
    window.setTimeout(labelTopBarControls, 0);
  });
})();
