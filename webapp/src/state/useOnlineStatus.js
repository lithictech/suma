import React from "react";

const useOnlineStatus = () => {
  const [isOnline, setIsOnline] = React.useState(true);
  const [statusInterval, setStatusInterval] = React.useState(null);
  const defaultIntervalDuration = 20000;
  const [intervalDuration, setIntervalDuration] = React.useState(defaultIntervalDuration);

  const handleCheckStatus = React.useCallback(() => {
    const statusVerifier = fetch("/favicon.ico");
    Promise.resolve(statusVerifier)
      .then((online) => {
        setIsOnline(online.status >= 200 && online.status < 300);
      })
      .catch(() => {
        setIsOnline(false);
      })
      .finally(() => {
        setIntervalDuration(isOnline ? defaultIntervalDuration : 5000);
      });
  }, [isOnline]);

  React.useEffect(() => {
    handleCheckStatus();
    setStatusInterval(
      setInterval(() => {
        handleCheckStatus();
      }, intervalDuration)
    );
  }, [intervalDuration, handleCheckStatus]);

  React.useEffect(() => {
    return () => {
      if (statusInterval) {
        clearInterval(statusInterval);
      }
    };
  }, [statusInterval]);

  return { isOnline, setIsOnline };
};

export { useOnlineStatus };
