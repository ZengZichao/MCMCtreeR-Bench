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
    if (theme !== "dark" && theme !== "light") return;
    var write = function() {
      document.documentElement.setAttribute("data-bs-theme", theme);
    };
    write();
    // bslib's dark-mode input initialises from its own mode attribute after
    // the first render, so a single early write gets overwritten. Re-assert it
    // once the widget has booted and push the value through the input as well.
    window.setTimeout(write, 300);
    window.setTimeout(write, 900);
    window.setTimeout(write, 1800);
    setInput("theme-theme_mode", theme);
  }

  function normalizeTheme() {
    var theme = document.documentElement.getAttribute("data-bs-theme");
    if (theme !== "light" && theme !== "dark") {
      document.documentElement.setAttribute("data-bs-theme", "light");
    }
  }

  function syncDocumentLanguage() {
    var select = document.querySelector(".lang-switch select");
    var value = select ? select.value : null;
    if (value !== "zh" && value !== "en") {
      try {
        value = window.localStorage.getItem("mcmctreer.lang");
      } catch (e) {
        value = null;
      }
    }
    document.documentElement.lang = value === "zh" ? "zh-CN" : "en";
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

  function centerActiveStep() {
    var lists = document.querySelectorAll(".step-list");
    for (var i = 0; i < lists.length; i++) {
      var list = lists[i];
      var active = list.querySelector(".step-btn.active");
      if (!active || list.scrollWidth <= list.clientWidth + 1) continue;
      var listRect = list.getBoundingClientRect();
      var activeRect = active.getBoundingClientRect();
      var delta = activeRect.left - listRect.left -
        (listRect.width - activeRect.width) / 2;
      list.scrollLeft = Math.max(
        0,
        Math.min(
          list.scrollLeft + delta,
          list.scrollWidth - list.clientWidth
        )
      );
    }
  }

  function syncStepLayout() {
    var grid = document.querySelector(".workbench-grid");
    var active = document.querySelector(".step-list .step-btn.active .step-index");
    if (!grid) return;
    var isFinal = active && active.textContent.trim() === "6";
    grid.classList.toggle("is-final-step", !!isFinal);
  }

  function labelTopBarControls() {
    var langSelect = document.querySelector(".lang-switch select");
    if (langSelect && !langSelect.getAttribute("aria-label")) {
      langSelect.setAttribute("aria-label", "Language / 语言");
    }
    var themeSelect = document.querySelector(".theme-switch select");
    if (themeSelect && !themeSelect.getAttribute("aria-label")) {
      themeSelect.setAttribute("aria-label", "Preview colours / 预览配色");
    }
    // The settings rail is never collapsible, so drop bslib's toggle entirely
    // rather than leaving a hidden-but-focusable button.
    var toggles = document.querySelectorAll(".bslib-sidebar-layout button.collapse-toggle");
    for (var i = 0; i < toggles.length; i++) {
      if (toggles[i].parentNode) toggles[i].parentNode.removeChild(toggles[i]);
    }
    var layout = document.querySelector(".bslib-sidebar-layout");
    if (layout && layout.classList.contains("sidebar-collapsed")) {
      layout.classList.remove("sidebar-collapsed");
    }
  }

  // bslib only shrinks the sidebar column; the controls stay focusable, so a
  // keyboard user can tab into a rail that is no longer on screen.
  function syncSidebarInert() {
    var layout = document.querySelector(".bslib-sidebar-layout");
    var sidebar = layout ? layout.querySelector(".sidebar") : null;
    if (!sidebar) return;
    var collapsed = layout.classList.contains("sidebar-collapsed");
    if (collapsed) {
      sidebar.setAttribute("inert", "");
      sidebar.setAttribute("aria-hidden", "true");
    } else {
      sidebar.removeAttribute("inert");
      sidebar.removeAttribute("aria-hidden");
    }
  }

  function labelPlots() {
    var plots = document.querySelectorAll(".shiny-plot-output img");
    for (var i = 0; i < plots.length; i++) {
      var img = plots[i];
      var alt = img.getAttribute("alt") || "";
      if (img.closest(".a-preview")) {
        alt = "Phylogenetic tree preview with node numbers and tip labels / 带节点编号和末端名称的系统发育树预览";
      } else if (img.closest(".b-plot-wrap")) {
        alt = "Time-calibrated tree figure with geological time scale and node uncertainty / 含地质时间尺和节点不确定性的时间树图";
      } else if (img.closest(".result-card")) {
        alt = "Prior distribution plot / 先验分布图";
      } else if (img.closest(".step-block")) {
        alt = "Calibrated tree preview / 标定树预览";
      }
      if (alt) img.setAttribute("alt", alt);
    }
  }

  function syncPageTitle() {
    var tab = document.querySelector(".navbar .nav-link.active");
    var label = tab ? tab.textContent.trim() : "";
    document.title = label
      ? "MCMCtreeR Bench | " + label
      : "MCMCtreeR Bench | Priors and time trees";
  }

  // shiny::modalDialog renders a titled dialog but never wires the title to the
  // dialog, so screen readers announce an unnamed "dialog" and focus starts on
  // the container rather than on the dismiss control.
  var modalSeq = 0;
  function labelModals() {
    var open = document.querySelectorAll(".modal.show, .modal.in");
    for (var i = 0; i < open.length; i++) {
      var dialog = open[i];
      var title = dialog.querySelector(".modal-title");
      if (title && !dialog.getAttribute("aria-labelledby")) {
        if (!title.id) {
          modalSeq += 1;
          title.id = "mcmctreer-modal-title-" + modalSeq;
        }
        dialog.setAttribute("aria-labelledby", title.id);
      }
      if (dialog.getAttribute("data-focus-done") || !title) continue;
      dialog.setAttribute("data-focus-done", "1");
    }
  }

  // Bootstrap moves focus to the dialog container when it finishes animating,
  // so the useful control has to be focused after that, not before.
  document.addEventListener("shown.bs.modal", function (event) {
    var dialog = event.target;
    if (!dialog) return;
    dialog.setAttribute("aria-hidden", "false");
    var target = dialog.querySelector(".modal-footer .btn") ||
      dialog.querySelector(".modal-footer button") ||
      dialog.querySelector(".modal-content a[href]");
    if (target && typeof target.focus === "function") target.focus();
  });

  // Shiny's notification container ships without any ARIA semantics, so error
  // toasts are never announced.
  function labelNotifications() {
    var notes = document.querySelectorAll(".shiny-notification");
    for (var i = 0; i < notes.length; i++) {
      var n = notes[i];
      var isError = /error/i.test(n.className || "");
      if (!n.getAttribute("role")) {
        n.setAttribute("role", isError ? "alert" : "status");
      }
      if (!n.getAttribute("aria-live")) {
        n.setAttribute("aria-live", isError ? "assertive" : "polite");
      }
    }
  }

  function afterRender() {
    normalizeTheme();
    syncDocumentLanguage();
    centerActiveStep();
    syncStepLayout();
    syncSidebarInert();
    labelTopBarControls();
    labelPlots();
    labelModals();
    labelNotifications();
    syncPageTitle();
    window.setTimeout(centerActiveStep, 200);
    window.setTimeout(centerActiveStep, 800);
    window.setTimeout(syncStepLayout, 200);
    window.setTimeout(syncStepLayout, 800);
    window.setTimeout(labelPlots, 300);
    window.setTimeout(labelPlots, 1200);
    window.setTimeout(labelModals, 300);
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

  document.addEventListener("shiny:connected", function () {
    registerHandlers();
    applyQueryTheme();
    sendInitialValues();
    window.setTimeout(afterRender, 0);
  });

  document.addEventListener("shiny:value", function () {
    window.setTimeout(afterRender, 0);
  });

  document.addEventListener("shiny:inputchanged", function (event) {
    var name = event.name || (event.detail && event.detail.name);
    if (name === "i18n-lang") {
      window.setTimeout(syncDocumentLanguage, 0);
    }
  });

  document.addEventListener("shiny:idle", function () {
    window.setTimeout(afterRender, 0);
  });

  document.addEventListener("DOMContentLoaded", function () {
    applyQueryTheme();
    if (window.MutationObserver) {
      new MutationObserver(function () {
        labelPlots();
        labelNotifications();
        labelModals();
      }).observe(document.body, { childList: true, subtree: true });
    }
    // Fallback for pages where shiny:connected fires before this listener.
    window.setTimeout(function () {
      registerHandlers();
      applyQueryTheme();
      sendInitialValues();
      afterRender();
      window.setTimeout(syncDocumentLanguage, 800);
    }, 400);
  });

  window.addEventListener("resize", function () {
    centerActiveStep();
  });

  document.addEventListener("change", function (event) {
    if (event.target && event.target.closest &&
        event.target.closest(".lang-switch")) {
      window.setTimeout(syncDocumentLanguage, 0);
    }
  });

  document.addEventListener("click", function (event) {
    window.setTimeout(afterRender, 0);
    window.setTimeout(syncSidebarInert, 400);

    var copyButton = event.target && event.target.closest
      ? event.target.closest(".js-copy-tre")
      : null;
    if (copyButton) {
      event.preventDefault();
      var target = document.getElementById(
        copyButton.getAttribute("data-copy-target")
      );
      if (!target) return;
      var label = copyButton.getAttribute("data-copy-label") ||
        copyButton.textContent;
      var copied = copyButton.getAttribute("data-copied") || "Copied";
      var showCopied = function () {
        copyButton.textContent = copied;
        window.setTimeout(function () {
          copyButton.textContent = label;
        }, 1600);
      };
      var fallback = function () {
        var range = document.createRange();
        range.selectNodeContents(target);
        var selection = window.getSelection();
        selection.removeAllRanges();
        selection.addRange(range);
        try {
          document.execCommand("copy");
          showCopied();
        } catch (e) {
          // Leave the selection in place so the user can copy manually.
        }
      };
      if (navigator.clipboard && typeof navigator.clipboard.writeText === "function") {
        navigator.clipboard.writeText(target.innerText).then(showCopied, fallback);
      } else {
        fallback();
      }
      return;
    }

    var tab = event.target && event.target.closest
      ? event.target.closest(".navbar .nav-link[data-toggle='tab'], .navbar .nav-link[data-bs-toggle='tab']")
      : null;
    if (!tab) return;

    var collapse = document.querySelector(".navbar-collapse");
    if (!collapse || !collapse.classList.contains("show")) return;

    if (window.bootstrap && window.bootstrap.Collapse) {
      window.bootstrap.Collapse.getOrCreateInstance(collapse).hide();
    } else {
      collapse.classList.remove("show");
    }
  });
})();
