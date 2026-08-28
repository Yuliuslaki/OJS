/**
 * Membersihkan placeholder mentah pada pratinjau template email.
 */
(function () {
  "use strict";

  const PATCH_FLAG = "__scienticoComposerPreviewPatchedV100";
  let attempts = 0;

  function installPatch() {
    attempts += 1;

    if (window[PATCH_FLAG]) {
      return;
    }

    const registry = window.pkp && window.pkp.registry;

    if (!registry || typeof registry.getComponent !== "function") {
      if (attempts < 50) {
        window.setTimeout(installPatch, 50);
      }
      return;
    }

    const composer = registry.getComponent("PkpComposer");

    if (
      !composer ||
      !composer.methods ||
      typeof composer.methods.getBodySnippet !== "function"
    ) {
      if (attempts < 50) {
        window.setTimeout(installPatch, 50);
      }
      return;
    }

    const originalGetBodySnippet = composer.methods.getBodySnippet;

    function getCleanBodySnippet(str) {
      let rendered = str || "";

      if (typeof this.renderPreparedContent === "function") {
        rendered = this.renderPreparedContent(
          rendered,
          this.localizedVariables || [],
        );
      }

      const container = document.createElement("span");
      container.innerHTML = rendered;

      Array.from(container.querySelectorAll("*"))
        .reverse()
        .forEach(function (element) {
          if (
            !element.children.length &&
            /\{\$[^}]+\}/.test(element.textContent || "")
          ) {
            element.remove();
          }
        });

      const cleaned = (container.textContent || "")
        .replace(/\{\$[^}]+\}/g, "")
        .replace(/\s+/g, " ")
        .replace(/\s+([,.;:!?])/g, "$1")
        .trim();

      return originalGetBodySnippet.call(this, cleaned);
    }

    getCleanBodySnippet.__scienticoPatched = true;
    composer.methods.getBodySnippet = getCleanBodySnippet;
    window[PATCH_FLAG] = true;
  }

  installPatch();
})();
