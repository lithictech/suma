export class Logger {
  constructor(name, options) {
    const { tags, context } = options || {};
    this.name = name;
    this._tags = tags || {};
    this._context = context || {};
  }

  tags(tags) {
    return new Logger(this.name, {
      tags: { ...this._tags, ...tags },
      context: this._context,
    });
  }

  context(context) {
    return new Logger(this.name, {
      tags: this._tags,
      context: { ...this._context, ...context },
    });
  }

  debug(...msg) {
    console.debug(...this._buildConsoleMsg(msg));
  }

  info(...msg) {
    console.log(...this._buildConsoleMsg(msg));
  }

  error(...msg) {
    console.error(...this._buildConsoleMsg(msg));
    // TODO: Report error somehow
    // captureMessage(msg.map(stringifyNonString).join(", "), ctx);
  }

  _buildConsoleMsg(msgArr) {
    const arr = [`[${this.name}]`, ...msgArr.map(stringifyNonString)];
    // Tags first because context can be big
    Object.entries(this._tags).forEach(([k, v]) =>
      arr.push(`${k}=${stringifyNonString(v)}`)
    );
    Object.entries(this._context).forEach(([k, v]) =>
      arr.push(`${k}=${stringifyNonString(v)}`)
    );
    return arr;
  }

  exception(exc) {
    console.error(exc);
    // TODO: Report error somehow
    // captureException(exc, ctx);
  }
}

function stringifyNonString(o) {
  return typeof o === "string" ? o : JSON.stringify(o);
}
