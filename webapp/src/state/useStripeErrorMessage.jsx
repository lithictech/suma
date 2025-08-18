import { Lookup } from "../localization/index.jsx";
import useI18n from "../localization/useI18n.jsx";
import useMountEffect from "../shared/react/useMountEffect.jsx";
import get from "lodash/get.js";
import React from "react";

/**
 * Given a Stripe error response, return a localized message.
 * - If the data doesn't look like a Stripe error, return null
 *   so the caller can handle it differently.
 * - Get the /static_strings/<locale>/stripe endpoint response.
 *   This internally maps static strings
 *   like {key: "errors.card_invalid_cvc", en: "Bad CVC"}
 *   to stripe error codes like "incorrect_cvc",
 *   and returns i18n-compatible strings, like:
 *   {incorrect_cvc: "Bad CVC"}.
 * - Lookup the Stripe error code ("incorrect_cvc") in the Stripe namespace
 *   and return the localized text ("Bad CVC").
 * - If the code is unmapped, log a normal missing localization error,
 *   but use data.error.message instead of the localization key.
 *   This is a nicer fallback.
 * @returns {{localizeStripeError: ((function(*): void)|*)}}
 */
export default function useStripeErrorMessage() {
  const { loadLanguageFileUnsafe } = useI18n();
  const [loaded, setLoaded] = React.useState(false);

  useMountEffect(() =>
    loadLanguageFileUnsafe("stripe")
      .then(() => setLoaded(true))
      .catch(() => null)
  );

  const localizeStripeError = React.useCallback(
    (data) => {
      if (!get(data, "error.type")) {
        return null;
      } else if (!loaded) {
        // Use the default message if our namespace isn't loaded.
        return data.error.message;
      }
      const key = `errors.${data.error.code}`;
      const localized = stripeTextLookup.t(key);
      if (localized.endsWith(key)) {
        return data.error.message;
      }
      return localized;
    },
    [loaded]
  );
  return { localizeStripeError };
}

const stripeTextLookup = new Lookup("stripe");
