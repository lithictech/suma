// See webapp config.js for explanation.
const env = window.sumaDynamicEnv || import.meta.env;

// If the API host is configured, use that.
// If it's '/', assume we mean 'the same server',
// and use an empty string. Otherwise, fall back to local dev,
// which is usually a different server to the React dev server.
let apiHost = env.VITE_API_HOST;
if (apiHost === "/") {
  apiHost = "";
} else if (!apiHost) {
  apiHost = `http://localhost:22001`;
}
const config = {
  apiHost: apiHost,
  chaos: env.VITE_CHAOS,
  debug: env.VITE_DEBUG,
  environment: env.NODE_ENV,
  defaultCurrency: { code: "USD", symbol: "$" },
};
config.defaultZeroMoney = { cents: 0, currency: config.defaultCurrency.code };

export default config;
