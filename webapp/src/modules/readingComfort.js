const STORAGE_KEY = "sumaReadingComfort";
const CLASS_NAME = "a11y-spacing";

/**
 * 'Reading comfort' adds more spacing between lines and paragraphs
 * (WCAG 1.4.8 Visual Presentation). The styles are under `html.a11y-spacing`.
 * The choice is stored on the device.
 * @returns {boolean} True if reading comfort is turned on.
 */
export function getReadingComfort() {
  try {
    return window.localStorage.getItem(STORAGE_KEY) === "1";
  } catch (err) {
    return document.documentElement.classList.contains(CLASS_NAME);
  }
}

/**
 * Turn reading comfort on or off, and remember the choice.
 * @param {boolean} on
 */
export function setReadingComfort(on) {
  document.documentElement.classList.toggle(CLASS_NAME, Boolean(on));
  try {
    if (on) {
      window.localStorage.setItem(STORAGE_KEY, "1");
    } else {
      window.localStorage.removeItem(STORAGE_KEY);
    }
  } catch (err) {
    // Storage can be unavailable (private browsing, etc).
    // The choice still applies until the page is reloaded.
  }
}

/**
 * Apply the stored choice. Call when the app starts, before rendering.
 */
export function applyReadingComfort() {
  document.documentElement.classList.toggle(CLASS_NAME, getReadingComfort());
}
