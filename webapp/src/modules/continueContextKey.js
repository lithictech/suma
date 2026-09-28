/**
 * 'Continue' links do not say where they go (WCAG 2.4.9 Link Purpose),
 * so we add visually hidden text after the visible label, like 'Continue to checkout'.
 * Return the localization key of that text for the given destination.
 * @param {string} to Path the link goes to.
 * @returns {string}
 */
export default function continueContextKey(to) {
  const path = to || "";
  const found = DESTINATIONS.find(([prefix]) => path.startsWith(prefix));
  return found ? found[1] : "forms.continue_context_default";
}

const DESTINATIONS = [
  ["/checkout", "forms.continue_context_checkout"],
  ["/funding", "forms.continue_context_payment_methods"],
];
