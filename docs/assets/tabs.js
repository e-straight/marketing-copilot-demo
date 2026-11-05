(() => {
  const tabList = document.querySelector(".workshop-tabs");
  const tabs = Array.from(document.querySelectorAll(".tab"));
  const panels = Array.from(document.querySelectorAll(".tab-panel"));

  if (!tabList || tabs.length === 0 || panels.length === 0) {
    return;
  }

  tabList.setAttribute("role", "tablist");

  const panelIds = new Set(panels.map((panel) => panel.id));

  tabs.forEach((tab) => {
    const panelId = tab.hash.slice(1);
    tab.setAttribute("role", "tab");
    tab.setAttribute("aria-controls", panelId);
    tab.setAttribute("aria-selected", "false");
    tab.tabIndex = -1;
  });

  panels.forEach((panel) => {
    panel.setAttribute("role", "tabpanel");
    panel.setAttribute("aria-labelledby", `tab-${panel.id}`);
  });

  function activatePanel(panel, { focus = false, updateHash = false } = {}) {
    if (!panelIds.has(panel.id)) {
      return;
    }

    tabs.forEach((tab) => {
      const selected = tab.getAttribute("aria-controls") === panel.id;
      tab.setAttribute("aria-selected", String(selected));
      tab.tabIndex = selected ? 0 : -1;

      if (selected && focus) {
        tab.focus();
      }
    });

    panels.forEach((candidate) => {
      candidate.hidden = candidate !== panel;
    });

    if (updateHash) {
      history.pushState(null, "", `#${panel.id}`);
    }
  }

  function revealHashTarget({ focus = false } = {}) {
    const target = document.getElementById(window.location.hash.slice(1));
    const panel = target?.closest(".tab-panel") ?? panels[0];
    activatePanel(panel, { focus });

    if (target && target !== panel) {
      requestAnimationFrame(() => target.scrollIntoView());
    }
  }

  revealHashTarget();
  document.documentElement.classList.add("tabs-enhanced");

  tabs.forEach((tab, index) => {
    tab.addEventListener("click", (event) => {
      event.preventDefault();
      const panel = document.getElementById(tab.getAttribute("aria-controls"));
      if (panel) {
        activatePanel(panel, { updateHash: true });
      }
    });

    tab.addEventListener("keydown", (event) => {
      let nextIndex;

      if (event.key === "ArrowRight" || event.key === "ArrowDown") {
        nextIndex = (index + 1) % tabs.length;
      } else if (event.key === "ArrowLeft" || event.key === "ArrowUp") {
        nextIndex = (index - 1 + tabs.length) % tabs.length;
      } else if (event.key === "Home") {
        nextIndex = 0;
      } else if (event.key === "End") {
        nextIndex = tabs.length - 1;
      } else {
        return;
      }

      event.preventDefault();
      const nextTab = tabs[nextIndex];
      const panel = document.getElementById(nextTab.getAttribute("aria-controls"));
      if (panel) {
        activatePanel(panel, { focus: true, updateHash: true });
      }
    });
  });

  window.addEventListener("hashchange", () => revealHashTarget());
})();
