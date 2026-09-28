import { sessionStorageCache } from "../localStorageHelper";
import debounce from "lodash/debounce";
import isEmpty from "lodash/isEmpty";
import pick from "lodash/pick";
import React from "react";

const KEY_PREFIX = "formdraft:";

/**
 * Return the storage key for the draft of the form on the given page.
 * @param {string=} pathname Defaults to the current page path.
 * @param {string=} suffix Use when there can be multiple forms on a page.
 * @returns {string}
 */
export function formDraftKey(pathname, suffix) {
  const path = pathname || window.location.pathname;
  return `${KEY_PREFIX}${path}${suffix ? `#${suffix}` : ""}`;
}

/**
 * @param {string} key
 * @returns {object} The stored draft, or an empty object.
 */
export function readFormDraft(key) {
  const draft = sessionStorageCache.getItem(key, {});
  if (!draft || typeof draft !== "object" || Array.isArray(draft)) {
    return {};
  }
  return draft;
}

/**
 * Store the draft. If there is nothing worth storing
 * (all values are empty), remove the draft instead.
 * @param {string} key
 * @param {object} values
 */
export function writeFormDraft(key, values) {
  const hasValue = Object.values(values || {}).some(
    (v) => v !== undefined && v !== null && v !== "" && v !== false
  );
  if (!hasValue) {
    sessionStorageCache.removeItem(key);
    return;
  }
  sessionStorageCache.setItem(key, values);
}

export function clearFormDraft(key) {
  sessionStorageCache.removeItem(key);
}

/**
 * Remove all form drafts, like when the user signs out.
 */
export function clearAllFormDrafts() {
  try {
    const store = window.sessionStorage;
    const keys = [];
    for (let i = 0; i < store.length; i++) {
      const k = store.key(i);
      if (k && k.startsWith(KEY_PREFIX)) {
        keys.push(k);
      }
    }
    keys.forEach((k) => store.removeItem(k));
  } catch (err) {
    console.log("Clear form drafts error:", err);
  }
}

/**
 * Keep a draft of react-hook-form values in session storage,
 * so what the user entered is not lost if they have to sign in again
 * or the page is reloaded before the form is submitted (WCAG 2.2.5 Re-authenticating).
 *
 * - Values are mirrored to session storage (debounced) as they change, using `watch`.
 * - The draft is restored when the form mounts: each stored value is passed to `setValue`,
 *   and `onRestore` is called with the draft so forms that also keep values
 *   in component state can update it.
 * - Call `clearDraft` when the form is submitted successfully.
 *
 * IMPORTANT: Never use this for sensitive fields, like card numbers, security codes,
 * bank account or routing numbers. Pass `fields` to limit what is stored.
 *
 * @param {function} watch From useForm.
 * @param {function} setValue From useForm.
 * @param {Array<string>} fields Names of the fields to store. Only these are stored and restored.
 * @param {function=} onRestore Called on mount with the restored draft, if there is one.
 * @param {string=} storageKey Defaults to a key derived from the current page path.
 * @param {number=} wait Debounce milliseconds.
 * @returns {{clearDraft: function}}
 */
export default function useFormDraft({
  watch,
  setValue,
  fields,
  onRestore,
  storageKey,
  wait,
}) {
  const keyRef = React.useRef(storageKey || formDraftKey());
  const fieldsRef = React.useRef(fields || []);
  const onRestoreRef = React.useRef(onRestore);
  onRestoreRef.current = onRestore;
  const saveRef = React.useRef(null);

  React.useEffect(() => {
    const draft = pick(readFormDraft(keyRef.current), fieldsRef.current);
    if (isEmpty(draft)) {
      return;
    }
    Object.entries(draft).forEach(([name, value]) => setValue(name, value));
    onRestoreRef.current && onRestoreRef.current(draft);
  }, [setValue]);

  React.useEffect(() => {
    const save = debounce(
      (values) => writeFormDraft(keyRef.current, pick(values, fieldsRef.current)),
      wait || 300
    );
    saveRef.current = save;
    const subscription = watch((values) => save(values));
    return () => {
      subscription.unsubscribe();
      // Write any pending change, so we do not lose the last thing typed.
      save.flush();
    };
  }, [wait, watch]);

  const clearDraft = React.useCallback(() => {
    saveRef.current && saveRef.current.cancel();
    clearFormDraft(keyRef.current);
  }, []);

  return React.useMemo(() => ({ clearDraft }), [clearDraft]);
}
