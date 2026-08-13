import React from "react";

export default function useOnlineStatus() {
  const [isOnline, setIsOnline] = React.useState(window.navigator.onLine);

  React.useEffect(() => {
    const abortCtrl = new AbortController();
    window.addEventListener("offline", () => setIsOnline(false), {
      signal: abortCtrl.signal,
    });
    window.addEventListener("online", () => setIsOnline(true), {
      signal: abortCtrl.signal,
    });
    return () => abortCtrl.abort();
  }, []);

  return { isOnline };
}
