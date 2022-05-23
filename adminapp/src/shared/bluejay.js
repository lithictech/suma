import Promise from "bluebird";

Promise.delayOr = function delayOr(durationMs, otherPromise, options) {
  options = options || { buffer: 100 };
  const started = Date.now();
  return otherPromise.then((r) => {
    const waited = Date.now() - started;
    const stillLeftToWait = durationMs - waited;
    // If we have a number of milliseconds or less than buffer left to wait,
    // we can return the original result without delay, because we know we took about durationMs.
    if (stillLeftToWait <= options.buffer) {
      return r;
    }
    // Otherwise, we should delay until the intended elapsed time has been reached.
    return Promise.delay(stillLeftToWait, r);
  });
};

Promise.prototype.delayOr = function delayOr(durationMs, options) {
  return Promise.delayOr(durationMs, this, options);
};

Promise.prototype.tapTap = function tapTap(f) {
  return this.tap(f).tapCatch(f);
};

Promise.config({
  cancellation: true,
  longStackTraces: process.env.REACT_APP_DEBUG,
  warnings: process.env.REACT_APP_DEBUG,
});

export default Promise;
