import { preact } from "@preact/preset-vite";
import { defineConfig } from "vite";
import eslint from "vite-plugin-eslint";
import svgr from "vite-plugin-svgr";

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [
    preact(),
    eslint(),
    svgr({
      svgrOptions: { icon: true },
    }),
  ],
  build: {
    outDir: "../build-webapp",
    emptyOutDir: true,
  },
});
