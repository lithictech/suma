import { Logger } from "../shared/logger";

const logger = new Logger("idempotency");

const store = {};

/**
 * Run a callback function that returns a promise,
 * such that it is only invoked once before it entirely resolves/rejects.
 * Usually wrap button submit actions with this,
 * where the submit causes some side effects
 * that should only happen once.
 *
 *   runAsync('somefunc', () => api.sendMoney())
 */
function runAsync(key, callback) {
  if (store[key]) {
    logger.context({ idempotency: key }).debug("idempotency_hit");
    return store[key];
  }
  store[key] = new Promise((resolve, reject) => {
    callback()
      .then((v) => {
        store[key] = null;
        resolve(v);
      })
      .catch((r) => {
        store[key] = null;
        reject(r);
      });
  });
  return store[key];
}

export default {
  runAsync,
};
