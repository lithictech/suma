const config = {
  environment: process.env.REACT_APP_ENVIRONMENT || "development",
  sumaApiHost: process.env.REACT_APP_SUMA_API_HOST || `http://localhost:3000/`,
};

export default config;