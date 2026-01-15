(() => {
  const ready = (fn) => {
    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", fn);
    } else {
      fn();
    }
  };

  const isBlank = (value) => !value || value.trim() === "";

  const buildNotice = (message) => {
    const template = document.getElementById("inline-validation-template");
    if (template && template.content) {
      const fragment = template.content.cloneNode(true);
      const notice = fragment.querySelector("[data-inline-validation]");
      const textNode = notice && notice.querySelector(".inline-validation__text");
      if (textNode) {
        textNode.textContent = message;
      }
      return notice || fragment;
    }
    const fallback = document.createElement("div");
    fallback.className = "inline-validation";
    fallback.textContent = message;
    fallback.setAttribute("role", "alert");
    return fallback;
  };

  const removeExistingNotice = (container) => {
    if (!container) return;
    const existing = container.querySelector("[data-inline-validation]");
    if (existing) existing.remove();
  };

  const showInlineNotice = (inputs, message) => {
    if (!inputs.length) return;
    const target = inputs[0];
    const container = target.closest(".field") || target.parentElement;
    if (!container) return;

    removeExistingNotice(container);
    const notice = buildNotice(message);
    if (!notice) return;
    container.appendChild(notice);
    target.focus({ preventScroll: false });
    if (typeof target.scrollIntoView === "function") {
      target.scrollIntoView({ behavior: "smooth", block: "center" });
    }

    const clearNotice = () => removeExistingNotice(container);
    inputs.forEach((input) => {
      const handler = () => {
        clearNotice();
        input.removeEventListener("input", handler);
        input.removeEventListener("change", handler);
      };
      input.addEventListener("input", handler);
      input.addEventListener("change", handler);
    });
  };

  ready(() => {
    const forms = document.querySelectorAll('[data-form-validation="true"]');
    if (!forms.length) return;

    forms.forEach((form) => {
      const rawFields = form.dataset.requiredFields || "";
      const requiredFields = rawFields
        .split(",")
        .map((field) => field.trim())
        .filter(Boolean);
      if (!requiredFields.length) return;

      const scope = form.dataset.paramScope || "";
      const message = form.dataset.validationMessage || "Please complete all fields before saving.";

      form.addEventListener("submit", (event) => {
        form.querySelectorAll("[data-inline-validation]").forEach((el) => el.remove());

        for (let i = 0; i < requiredFields.length; i += 1) {
          const field = requiredFields[i];
          const selector = scope
            ? `[name="${scope}[${field}]"], [name="${scope}[${field}][]"]`
            : `[name="${field}"]`;
          const inputs = form.querySelectorAll(selector);
          if (!inputs.length) continue;

          const fieldBlank = Array.from(inputs).every((input) => {
            if (input.type === "checkbox" || input.type === "radio") {
              return !input.checked;
            }
            return isBlank(input.value || "");
          });

          if (fieldBlank) {
            event.preventDefault();
            showInlineNotice(inputs, message);
            return;
          }
        }
      });
    });
  });
})();
