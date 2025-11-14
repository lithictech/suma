import config from "../config.js";

export function countEvent(name) {
  countMetric({ path: name, event: true });
}

/**
 * Record simple app metrics Goatcounter (https://www.goatcounter.com/),
 * which is usually self-hosted.
 * The JS here is based on counter.js, but works for a SPA and is more aligned
 * with our needs and usage (ie, it is not a port, does not support options, etc).
 *
 * Vars can be used to specify a different path, the event name, etc.
 * For events, use recordEven, since how goatcounter handles events is not super straightforward.
 * @param {{path: string=, event: boolean=}=} vars
 */
export function countMetric(vars) {
  if (!config.metricsEndpoint) {
    // Do nothing if metrics are not configured.
    return;
  }
  const filterReason = shouldFilter();
  if (filterReason) {
    return warn("not counting because of: " + filterReason);
  }
  const url = getUrl(vars);
  if (!url) {
    return warn("not counting because path path is empty");
  }
  fetch(url, { method: "POST", keepalive: true, mode: "no-cors" }).catch((r) => warn(r));
}

function shouldFilter() {
  if ("visibilityState" in document && document.visibilityState === "prerender") {
    return "visibilityState";
  }
  if (location !== parent.location) {
    return "frame";
  }
  return false;
}

/**
 * Get all data we're going to send off to the counter endpoint.
 */
function getData(vars) {
  vars = vars || {};
  const data = {
    p: vars.path || getPath(),
    r: document.referrer,
    t: document.title,
    e: !!vars.event,
    s: [window.screen.width, window.screen.height, window.devicePixelRatio || 1],
    b: isBot(),
    q: location.search,
  };
  return data;
}

/**
 * See if this looks like a bot; there is some additional filtering on the
 * backend, but these properties can't be fetched from there.
 */
function isBot() {
  // Headless browsers are probably a bot.
  const w = window;
  const d = document;
  if (w.callPhantom || w._phantom || w.phantom) return 150;
  if (w.__nightmare) return 151;
  if (d.__selenium_unwrapped || d.__webdriver_evaluate || d.__driver_evaluate) return 152;
  if (navigator.webdriver) return 153;
  return 0;
}

function getUrl(vars) {
  const data = getData(vars);
  if (data.p === null) {
    return;
  }
  // Browsers don't always listen to Cache-Control.
  data.rnd = Math.random().toString(36).substring(2, 7);
  const endpoint = config.metricsEndpoint;
  if (!endpoint) {
    return warn("no endpoint found");
  }
  return endpoint + urlencode(data);
}

/**
 * Object to urlencoded string, starting with a ?.
 */
function urlencode(obj) {
  const p = [];
  for (let k in obj)
    if (obj[k] !== "" && obj[k] !== null && obj[k] !== undefined && obj[k] !== false)
      p.push(encodeURIComponent(k) + "=" + encodeURIComponent(obj[k]));
  return "?" + p.join("&");
}

function getPath() {
  let loc = window.location;
  let c = document.querySelector('link[rel="canonical"][href]');
  if (c) {
    // May be relative or point to different domain.
    const a = document.createElement("a");
    a.href = c.href;
    if (a.hostname.replace(/^www\./, "") === location.hostname.replace(/^www\./, ""))
      loc = a;
  }
  return loc.pathname + loc.search || "/";
}

function warn(msg) {
  console.warn("goatcounter: ", msg);
}
