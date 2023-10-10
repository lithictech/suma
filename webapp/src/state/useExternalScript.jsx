import React from "react";

export const LOAD_STATE = {
  idle: "idle",
  loading: "loading",
  ready: "ready",
  error: "error",
};

export default function useExternalScript(src) {
  let [state, setState] = React.useState(src ? LOAD_STATE.loading : LOAD_STATE.idle);
  const setReady = React.useCallback(() => setState(LOAD_STATE.ready), []);
  const setError = React.useCallback(() => setState(LOAD_STATE.error), []);

  React.useEffect(() => {
    if (!src) {
      setState(LOAD_STATE.idle);
      return;
    }
    let script = document.querySelector(`script[src="${src}"]`);
    if (!script) {
      script = document.createElement("script");
      script.type = "application/javascript";
      script.src = src;
      script.async = true;
      document.body.appendChild(script);
      script.addEventListener("load", setReady);
      script.addEventListener("error", setError);
    }

    script.addEventListener("load", setReady);
    script.addEventListener("error", setError);

    return () => {
      script.removeEventListener("load", setReady);
      script.removeEventListener("error", setError);
    };
  }, [setError, setReady, src]);

  return state;
}
