import debounce from "lodash/debounce";
import React from "react";

export default function useDebounced(func, pthen, pcatch, { wait, maxWait }) {
  const activeAbortController = React.useRef(new AbortController());
  const debounced = React.useRef(
    debounce(
      (...args) => {
        activeAbortController.current.abort();
        const thisAbortCtrl = new AbortController();
        activeAbortController.current = thisAbortCtrl;
        let promise = func(...args);
        if (pthen) {
          promise = promise.then((r) => {
            if (!thisAbortCtrl.signal.aborted) {
              pthen(r);
            }
          });
        }
        if (pcatch) {
          promise = promise.catch((r) => {
            if (!thisAbortCtrl.signal.aborted) {
              pcatch(r);
            }
          });
        }
        return promise;
      },
      wait || 150,
      { maxWait: maxWait || 400 }
    )
  );
  return debounced.current;
}
