import * as Sentry from "@sentry/browser";

/**
 * Shim Sentry because if we expose it outside of this module
 * (like `cb(Sentry)` in `withSentry`) it does not get tree shaken,
 * so is much larger than it should be.
 *
 * Add more shim methods as needed.
 */
class SentryShim {
  withScope(cb: (scope: Sentry.Scope) => void) {
    return Sentry.withScope(cb);
  }
  setUser(user: Sentry.User | null) {
    Sentry.setUser(user);
  }
  captureMessage(message: string, context?: Parameters<typeof Sentry.captureMessage>[1]) {
    return Sentry.captureMessage(message, context);
  }
  captureException(ex: unknown, hint?: Parameters<typeof Sentry.captureException>[1]) {
    return Sentry.captureException(ex, hint);
  }
}

/**
 * Call cb(SentryShim), and console log if there is any sort of error.
 */
export function withSentry(cb: (shim: SentryShim) => void) {
  try {
    cb(new SentryShim());
  } catch (e) {
    console.error("Error calling Sentry:", e);
  }
}

interface InitSentryOptions extends Partial<Sentry.BrowserOptions> {
  application?: string;
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
  ignoreErrors,
  ...rest
}: InitSentryOptions) {
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
    integrations: [Sentry.browserTracingIntegration()],
    ignoreErrors: ignoreErrors || [
      "Network Error",
      "canceled", // Sometimes seen when aborting a request, like on page navigate
      "ECONNABORTED",
      /Request aborted/i,
      /Request failed with status code 4\d\d/,
      /timeout of \d+ms exceeded/i,
      /Invalid call to runtime\./,
      /[A-Z]+ \/[a-z]+\/v\d\/[a-zA-Z_\d/]+ \d+/, // GET /api/v1/commerce/offerings/18 403
    ],
    ...rest,
  });
  if (application) {
    Sentry.setTag("application", application);
  }
}
