/// <reference types="vite/client" />

declare global {
  interface Window {
    // Set server-side by Rack::DynamicConfigWriter when serving from the Ruby backend.
    sumaDynamicEnv?: Record<string, string>;
    __DEV__?: boolean;
  }
}

export {};