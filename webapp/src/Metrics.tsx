import config from "./config";
import history from "./history";
import { countMetric } from "./modules/metrics";
import useMountEffect from "./state/useMountEffect";
import React from "react";

let Metrics: React.ComponentType;

if (!config.metricsEndpoint) {
  /**
   * Noop for when metrics is not enabled.
   */
  Metrics = () => null;
} else {
  /**
   * Record metrics on navigation changes.
   */
  Metrics = () => {
    useMountEffect(() => {
      // Record where we are when the app starts.
      countMetric();
    });

    React.useEffect(() => {
      const unlisten = history.listen(({ location }) => {
        // Listen to every page change.
        countMetric({ path: location.pathname + location.search });
      });
      return () => unlisten();
    }, []);

    return null;
  };
}

export default Metrics;
