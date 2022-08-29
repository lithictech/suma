import React from "react";

export default function useOnlineStatus() {
  const [isOnline, setIsOnline] = React.useState(window.navigator.onLine);

  React.useEffect(() => {
    const abortCtrl = new AbortController();
    window.addEventListener("offline", (e) => setIsOnline(false), {
      signal: abortCtrl.signal,
    });
    window.addEventListener("online", (e) => setIsOnline(true), {
      signal: abortCtrl.signal,
    });
    return () => abortCtrl.abort();
  }, []);

  return { isOnline };
}
