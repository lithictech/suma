import config from "./config.js";
import history from "./history";
import { countMetric } from "./modules/metrics.js";
import useMountEffect from "./shared/react/useMountEffect.jsx";

let Metrics;

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

    const unlisten = history.listen(({ location }) => {
      // Listen to every page change.
      countMetric({ path: location.pathname + location.search });
    });

    return () => unlisten();
  };
}

export default Metrics;
