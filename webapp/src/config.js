// If the API host is configured, use that.
// If it's '/', assume we mean 'the same server',
// and use an empty string. Otherwise, fall back to local dev,
// which is usually a different server to the React dev server.
import { initSentry } from "./shared/sentry";

let apiHost = process.env.REACT_APP_API_HOST;
if (apiHost === "/") {
  apiHost = "";
} else if (!apiHost) {
  apiHost = `http://localhost:22001`;
}

function parseIfSet(key) {
  const s = process.env[key];
  if (!s) {
    return {};
  }
  try {
    return JSON.parse(s);
  } catch (e) {
    console.error(`Failed to parse ${key} into JSON`, e);
    return {};
  }
}

const config = {
  apiHost: apiHost,
  chaos: process.env.REACT_APP_CHAOS,
  debug: process.env.REACT_APP_DEBUG,
  environment: process.env.NODE_ENV,
  release: process.env.REACT_APP_RELEASE || "app.mysuma@localdev",
  sentryDsn: process.env.REACT_APP_SENTRY_DSN,
  stripePublicKey:
    process.env.REACT_APP_STRIPE_PUBLIC_KEY ||
    "pk_test_51KlS9cAqRmWQecssicpSG7l8AzzGttANpp4k1LKEnmvLiN6YnrcoHebK3QubwXwpJZzmSMwCOKtinnEyO6kMPQDn00rmqmhwML",
  devCardDetails: parseIfSet("REACT_APP_DEV_CARD_DETAILS"),
  devBankAccountDetails: parseIfSet("REACT_APP_DEV_BANK_ACCOUNT_DETAILS"),
};

initSentry({ dsn: config.sentryDsn, debug: config.debug, application: "web-app" });

export default config;
