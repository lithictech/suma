import * as Sentry from "@sentry/browser";

/**
 * Shim Sentry because if we expose it outside of this module
 * (like `cb(Sentry)` in `withSentry`) it does not get tree shaken,
 * so is much larger than it should be.
 *
 * Add more shim methods as needed.
 */
class SentryShim {
  captureMessage(message, context) {
    return Sentry.captureMessage(message, context);
  }
  captureException(ex, hint) {
    return Sentry.captureException(ex, hint);
  }
}

/**
 * Call cb(SentryShim), and console log if there is any sort of error.
 * @param {function(SentryShim)} cb
 */
export function withSentry(cb) {
  try {
    cb(new SentryShim());
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
