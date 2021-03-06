// If the API host is configured, use that.
// If it's '/', assume we mean 'the same server',
// and use an empty string. Otherwise, fall back to local dev,
// which is usually a different server to the React dev server.
let apiHost = process.env.REACT_APP_API_HOST;
if (apiHost === "/") {
  apiHost = "";
} else if (!apiHost) {
  apiHost = `http://localhost:22001`;
}
const config = {
  apiHost: apiHost,
  chaos: process.env.REACT_APP_CHAOS,
  debug: process.env.REACT_APP_DEBUG,
  environment: process.env.NODE_ENV,
};

export default config;
