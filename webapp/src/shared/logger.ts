import { withSentry } from "./sentry";

interface LoggerOptions {
  tags?: Record<string, any>;
  context?: Record<string, any>;
}

declare global {
  interface Window {
    // Exposed for debugging from the browser console.
    SumaLogger?: typeof Logger;
  }
}

export class Logger {
  name: string;
  _tags: Record<string, any>;
  _context: Record<string, any>;

  constructor(name: string, options?: LoggerOptions) {
    const { tags, context } = options || {};
    this.name = name;
    this._tags = tags || {};
    this._context = context || {};
  }

  tags(tags: Record<string, any>) {
    return new Logger(this.name, {
      tags: { ...this._tags, ...tags },
      context: this._context,
    });
  }

  context(context: Record<string, any>) {
    return new Logger(this.name, {
      tags: this._tags,
      context: { ...this._context, ...context },
    });
  }

  debug(event: string, fields?: Record<string, any>) {
    console.debug(...this._buildConsoleMsg(event, fields));
  }

  info(event: string, fields?: Record<string, any>) {
    console.log(...this._buildConsoleMsg(event, fields));
  }

  error(event: string, fields?: Record<string, any>) {
    console.error(...this._buildConsoleMsg(event, fields));
    this._withSentry(function (sentry) {
      sentry.captureMessage(event, "error");
    });
  }

  exception(event: string, exc: unknown, fields?: Record<string, any>) {
    this._withSentry(function (sentry) {
      sentry.captureException(exc);
    });
    console.error(...this._buildConsoleMsg(event, fields));
  }

  _buildConsoleMsg(event: string, fields?: Record<string, any>) {
    fields = fields || {};
    const arr = [`[${this.name}]`, event];
    // Tags first because context can be big
    Object.entries(this._tags).forEach(([k, v]) =>
      arr.push(`${k}=${stringifyNonString(v)}`)
    );
    const ctx = { ...this._context, ...fields };
    Object.entries(ctx).forEach(([k, v]) => arr.push(`${k}=${stringifyNonString(v)}`));
    return arr;
  }

  _withSentry(cb: (sentry: any) => void) {
    withSentry((sentry) => {
      sentry.withScope((scope: any) => {
        scope.setTags({ logger: this.name, ...this._tags });
        scope.setExtras(this._context);
        cb(sentry);
      });
    });
  }
}

function stringifyNonString(o: any) {
  return typeof o === "string" ? o : JSON.stringify(o);
}

window.SumaLogger = Logger;
