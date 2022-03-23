const config = {
  apiHost: process.env.REACT_APP_API_HOST || `http://localhost:22001`,
  chaos: process.env.REACT_APP_CHAOS,
  debug: process.env.REACT_APP_DEBUG,
  environment: process.env.NODE_ENV,
};

export default config;
