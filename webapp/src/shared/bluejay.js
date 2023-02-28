import uniqueId from "lodash/uniqueId";

const Promise = window.Promise;

Promise.prototype._then = Promise.prototype.then;

/**
 * Subclass this when unhandled rejections should ignore the error.
 */
class IgnorablePromiseError extends Error {}
class CancelationError extends IgnorablePromiseError {}

/**
 * Whenever we create a promise, set the promise that spawned it.
 * @param parent {Promise}
 * @param child {Promise}
 * @returns {Promise} child
 */
function setParent(parent, child) {
  if (parent.__id === child.__id || child.__parent) {
    return child;
  }
  child.__parent = parent;
  return child;
}

/**
 * Whenever we create a promise, set an ID so we can uniquely identify it.
 * @param {Promise} p
 * @returns {Promise}
 */
function setId(p) {
  p.__id = p.__id || uniqueId('p')
  return p;
}

Promise.prototype.then = function then(onResolve, onReject) {
  const child = this._then(
    (value) => {
      if (this.isCanceled()) {
        return Promise.reject(new CancelationError())
      }
      if (onResolve) {
        return onResolve.call(null, value);
      }
    },
    (reason) => {
      if (this.isCanceled()) {
        return Promise.reject(new CancelationError())
      }
      if (onReject) {
        return onReject.call(null, reason)
      }
    })
  return setParent(this, setId(child))
}

Promise.prototype.catch = function catch_(onReject) {
  return this.then(null, onReject)
}

Promise.prototype.isCanceled = function isCanceled() {
  let parent = this;
  while (parent) {
    if (parent.__canceled) {
      return true;
    }
    parent = parent.__parent;
  }
  return false;
}

Promise.delay = function delay(durationMs, value) {
  return new Promise((resolve) => {
    setTimeout(() => resolve(value), durationMs);
  })
}

Promise.prototype.delay = function delay(durationMs) {
  return this.then((value) => Promise.delay(durationMs, value));
}

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

Promise.prototype.tap = function tap(callback) {
  return this.then(async function(value) {
    await callback(value)
    return value;
  })
}

Promise.prototype.tapCatch = function tapCatch(callback) {
  return this.catch(async function (reason) {
    await callback(reason);
    return Promise.reject(...arguments)
  })
};

Promise.prototype.tapTap = function tapTap(f) {
  return this.tap(f).tapCatch(f);
};

Promise.prototype.cancel = function cancel() {
  this.__canceled = true;
}

window.addEventListener('unhandledrejection', (event) => {
  if (event.reason instanceof IgnorablePromiseError) {
    event.preventDefault();
    return;
  }
  console.error('Unhandled rejection:', event.reason)
});
