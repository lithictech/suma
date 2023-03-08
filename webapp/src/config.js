import { initSentry } from "./shared/sentry";

// When we are serving from the Ruby backend, only use the config it provides.
// Otherwise we could accidentally template in values at build time (on staging)
// and carry them forward to runtime in a different env (on prod).
// We won't have sumaDynamicEnv set (by Rack::DynamicConfigWriter) when running
// the development server of React during local dev,
// or if this app is built and deployed separately as a static app.
const env = window.sumaDynamicEnv || process.env;

// If the API host is configured, use that.
// If it's '/', assume we mean 'the same server',
// and use an empty string. Otherwise, fall back to local dev,
// which is usually a different server to the React dev server.
let apiHost = env.REACT_APP_API_HOST;
if (apiHost === "/") {
  apiHost = "";
} else if (!apiHost) {
  apiHost = `http://localhost:22001`;
}

function parseIfSet(key) {
  const s = env[key];
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
  chaos: env.REACT_APP_CHAOS,
  debug: env.REACT_APP_DEBUG,
  environment: env.NODE_ENV,
  release: env.REACT_APP_RELEASE || "app.mysuma@localdev",
  sentryDsn: env.REACT_APP_SENTRY_DSN,
  stripePublicKey:
    env.REACT_APP_STRIPE_PUBLIC_KEY ||
    "pk_test_51LxdhVLelvCURGkUPdGCTS68je1xL8wWi0faS8hiDHbxxEPhmfcAX7EBDzMFTkb3N1Y0tB5vziqtsifKp6PQ4roM005GI4h8T3",
  devCardDetails: parseIfSet("REACT_APP_DEV_CARD_DETAILS"),
  devBankAccountDetails: parseIfSet("REACT_APP_DEV_BANK_ACCOUNT_DETAILS"),
  featureMobility: env.REACT_APP_FEATURE_MOBILITY,
};

initSentry({ dsn: config.sentryDsn, debug: config.debug, application: "web-app" });

export default config;
