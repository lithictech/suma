import * as Sentry from "@sentry/browser";

/**
 * Call cb(Sentry), and console log if there is any sort of error.
 * @param {function(Sentry)} cb
 */
export function withSentry(cb) {
  if (!Sentry) {
    console.warn("sentry was not available");
    return;
  }
  try {
    cb(Sentry);
  } catch (e) {
    console.error("Error calling Sentry:", e);
  }
}

/**
 * Conditionally initialize Sentry.
 * See https://docs.sentry.io/platforms/javascript/configuration/options/ for options.
 */
export function initSentry({
  application,
  dsn,
  debug,
  release,
  environment,
  allowUrls,
  ...rest
}) {
  if (!dsn) {
    return;
  }
  Sentry.init({
    dsn,
    debug,
    maxBreadcrumbs: 50,
    release,
    environment,
    allowUrls,
    sampleRate: 1.0,
    integrations: [new Sentry.browserTracingIntegration()],
    ...rest,
  });
  if (application) {
    Sentry.setTag("application", application);
  }
}
