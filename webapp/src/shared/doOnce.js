/**
 * There are times we may need to initialize global state just once,
 * like as part of a React mount effect. Use this to run something
 * just once ever for the page's lifetime (key is stored at module level).
 * @param {string} key
 * @param {function} cb
 * @returns {function}
 */
export default function doOnce(key, cb) {
  return (...args) => {
    if (done[key]) {
      return;
    }
    cb(...args);
    done[key] = true;
  };
}

const done = {};
