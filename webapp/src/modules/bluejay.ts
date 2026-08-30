interface DelayOptions {
  buffer?: number;
}

declare global {
  interface Promise<T> {
    delay(durationMs: number): Promise<T>;
    delayOr(durationMs: number, options?: DelayOptions): Promise<T>;
    tap(f: (value: T) => void): Promise<T>;
    tapCatch(f: (reason: Error) => void): Promise<T>;
    tapTap(f: (value: T) => void): Promise<T>;
  }

  interface PromiseConstructor {
    delay<T>(durationMs: number, p: Promise<T>): Promise<T>;
    delayOr<T>(
      durationMs: number,
      otherPromise: Promise<T>,
      options?: DelayOptions
    ): Promise<T>;
  }
}

export function installPromiseExtras(Promise: PromiseConstructor) {
  Promise.delay = function delay(durationMs, p) {
    return p.then((r) => {
      return new Promise((resolve) => {
        window.setTimeout(() => resolve(r), durationMs);
      });
    });
  };

  Promise.prototype.delay = function delay<T>(durationMs: number) {
    return Promise.delay<T>(durationMs, this);
  };

  Promise.delayOr = function delayOr(
    durationMs,
    otherPromise,
    options = { buffer: 100 }
  ) {
    const started = Date.now();
    return otherPromise.then((r) => {
      const waited = Date.now() - started;
      const stillLeftToWait = durationMs - waited;
      // If we have a number of milliseconds or less than buffer left to wait,
      // we can return the original result without delay, because we know we took about durationMs.
      if (stillLeftToWait <= (options.buffer as number)) {
        return r;
      }
      // Otherwise, we should delay until the intended elapsed time has been reached.
      return Promise.delay(stillLeftToWait, r as any);
    });
  };

  Promise.prototype.delayOr = function delayOr<T>(
    durationMs: number,
    options?: DelayOptions
  ) {
    return Promise.delayOr<T>(durationMs, this, options);
  };

  Promise.prototype.tap = function tap<T>(f: (r: T) => void) {
    return this.then((v) => {
      f(v);
      return v;
    });
  };

  Promise.prototype.tapCatch = function tapCatch(f) {
    return this.catch((r) => {
      f(r);
      return Promise.reject(r);
    });
  };

  Promise.prototype.tapTap = function tapTap<T>(f: (r: T | Error) => void) {
    return this.tap(f).tapCatch(f);
  };
}
