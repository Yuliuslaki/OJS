/**
 * ScientiCO Admin Mobile Navigation v1.3.0
 *
 * Mengubah sidebar backend OJS menjadi drawer hamburger
 * pada layar HP dan tablet.
 */

(function () {
  "use strict";

  if (window.__scienticoAdminMobileDrawerV130) {
    return;
  }

  window.__scienticoAdminMobileDrawerV130 = true;

  const MOBILE_QUERY = "(max-width: 991px)";
  const OPEN_CLASS = "scienticoAdminNavOpen";

  const TOGGLE_ID = "scientico-admin-nav-toggle";
  const NAV_ID = "scientico-admin-mobile-nav";
  const BACKDROP_ID = "scientico-admin-nav-backdrop";

  const NAV_CLASS = "scienticoAdminMobileNav";

  let preparationScheduled = false;

  function isMobile() {
    return window.matchMedia(MOBILE_QUERY).matches;
  }

  function getHeader() {
    return document.querySelector(".app__header");
  }

  function getAppBody() {
    return document.querySelector(".app__body");
  }

  function getMainContent() {
    const appBody = getAppBody();

    if (!appBody) {
      return null;
    }

    return (
      Array.from(appBody.children).find(function (element) {
        return element.classList.contains("app__main");
      }) || null
    );
  }

  function getNavigation() {
    const appBody = getAppBody();
    const mainContent = getMainContent();

    if (!appBody || !mainContent) {
      return null;
    }

    return (
      Array.from(appBody.children).find(function (element) {
        return element !== mainContent;
      }) || null
    );
  }

  function getToggleButton() {
    return document.getElementById(TOGGLE_ID);
  }

  function updateHeaderHeight() {
    const header = getHeader();

    if (!header) {
      return;
    }

    const headerHeight = Math.ceil(header.getBoundingClientRect().height);

    document.documentElement.style.setProperty(
      "--scientico-admin-header-height",
      `${headerHeight}px`,
    );
  }

  function updateAccessibility(open) {
    const navigation = getNavigation();
    const toggleButton = getToggleButton();

    if (toggleButton) {
      toggleButton.setAttribute("aria-expanded", open ? "true" : "false");

      toggleButton.setAttribute(
        "aria-label",
        open ? "Tutup menu dashboard" : "Buka menu dashboard",
      );
    }

    if (!navigation) {
      return;
    }

    if (!isMobile()) {
      navigation.removeAttribute("aria-hidden");
      return;
    }

    if (open) {
      navigation.removeAttribute("aria-hidden");
    } else {
      /*
       * Pindahkan fokus keluar dari sidebar sebelum
       * memasang aria-hidden agar tidak menimbulkan
       * peringatan aksesibilitas.
       */
      if (navigation.contains(document.activeElement) && toggleButton) {
        toggleButton.focus({
          preventScroll: true,
        });
      }

      navigation.setAttribute("aria-hidden", "true");
    }
  }

  function setNavigationOpen(open, restoreFocus) {
    const navigation = getNavigation();
    const toggleButton = getToggleButton();

    if (!navigation) {
      return;
    }

    const shouldOpen = isMobile() && open;

    if (
      !shouldOpen &&
      navigation.contains(document.activeElement) &&
      toggleButton
    ) {
      toggleButton.focus({
        preventScroll: true,
      });
    }

    document.body.classList.toggle(OPEN_CLASS, shouldOpen);

    updateAccessibility(shouldOpen);

    if (!shouldOpen && restoreFocus && toggleButton && isMobile()) {
      toggleButton.focus({
        preventScroll: true,
      });
    }
  }

  function toggleNavigation(event) {
    /*
     * Hentikan event agar handler global OJS tidak langsung
     * menutup kembali drawer setelah tombol diklik.
     */
    event.preventDefault();
    event.stopPropagation();
    event.stopImmediatePropagation();

    const currentlyOpen = document.body.classList.contains(OPEN_CLASS);

    setNavigationOpen(!currentlyOpen, false);
  }

  function createToggleButton(header) {
    let toggleButton = getToggleButton();

    if (!toggleButton) {
      toggleButton = document.createElement("button");

      toggleButton.id = TOGGLE_ID;
      toggleButton.className = "scienticoAdminNavToggle";
      toggleButton.type = "button";

      toggleButton.setAttribute("aria-controls", NAV_ID);

      toggleButton.setAttribute("aria-expanded", "false");

      toggleButton.setAttribute("aria-label", "Buka menu dashboard");

      toggleButton.innerHTML = [
        '<span class="scienticoAdminNavToggle__icon" aria-hidden="true">',
        "<span></span>",
        "<span></span>",
        "<span></span>",
        "</span>",
        '<span class="scienticoAdminNavToggle__text">Menu</span>',
      ].join("");

      header.insertBefore(toggleButton, header.firstChild);
    }

    if (toggleButton.dataset.scienticoMobileBound !== "true") {
      /*
       * Capture mode digunakan agar handler ini berjalan
       * sebelum delegated click handler milik OJS.
       */
      toggleButton.addEventListener("click", toggleNavigation, true);

      toggleButton.dataset.scienticoMobileBound = "true";
    }

    return toggleButton;
  }

  function createBackdrop() {
    let backdrop = document.getElementById(BACKDROP_ID);

    if (!backdrop) {
      backdrop = document.createElement("button");

      backdrop.id = BACKDROP_ID;
      backdrop.className = "scienticoAdminNavBackdrop";
      backdrop.type = "button";
      backdrop.tabIndex = -1;

      backdrop.setAttribute("aria-label", "Tutup menu dashboard");

      document.body.appendChild(backdrop);
    }

    if (backdrop.dataset.scienticoMobileBound !== "true") {
      backdrop.addEventListener(
        "click",
        function (event) {
          event.preventDefault();
          event.stopPropagation();

          setNavigationOpen(false, true);
        },
        true,
      );

      backdrop.dataset.scienticoMobileBound = "true";
    }

    return backdrop;
  }

  function prepareNavigation() {
    const header = getHeader();
    const navigation = getNavigation();

    if (!header || !navigation) {
      return;
    }

    navigation.id = NAV_ID;
    navigation.classList.add(NAV_CLASS);

    createToggleButton(header);
    createBackdrop();
    updateHeaderHeight();

    const currentlyOpen = document.body.classList.contains(OPEN_CLASS);

    updateAccessibility(isMobile() && currentlyOpen);

    document.documentElement.classList.add("scienticoAdminMobileReady");
  }

  function schedulePreparation() {
    if (preparationScheduled) {
      return;
    }

    preparationScheduled = true;

    window.requestAnimationFrame(function () {
      preparationScheduled = false;
      prepareNavigation();
    });
  }

  document.addEventListener("keydown", function (event) {
    if (
      event.key === "Escape" &&
      document.body.classList.contains(OPEN_CLASS)
    ) {
      event.preventDefault();
      setNavigationOpen(false, true);
    }
  });

  document.addEventListener(
    "click",
    function (event) {
      if (!isMobile() || !document.body.classList.contains(OPEN_CLASS)) {
        return;
      }

      const selectedLink = event.target.closest(`#${NAV_ID} a[href]`);

      if (selectedLink) {
        window.setTimeout(function () {
          setNavigationOpen(false, false);
        }, 0);
      }
    },
    false,
  );

  window.addEventListener("resize", function () {
    updateHeaderHeight();

    if (!isMobile()) {
      setNavigationOpen(false, false);
    } else {
      updateAccessibility(document.body.classList.contains(OPEN_CLASS));
    }
  });

  const observer = new MutationObserver(schedulePreparation);

  observer.observe(document.documentElement, {
    childList: true,
    subtree: true,
  });

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", prepareNavigation);
  } else {
    prepareNavigation();
  }
})();
