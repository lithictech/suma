/// <reference types="vitest/config" />
import { preact } from "@preact/preset-vite";
import { storybookTest } from "@storybook/addon-vitest/vitest-plugin";
// https://vitejs.dev/config/
import path from "node:path";
import { fileURLToPath } from "node:url";
import { defineConfig } from "vite";
import eslint from "vite-plugin-eslint";
import svgr from "vite-plugin-svgr";

const dirname =
  typeof __dirname !== "undefined"
    ? __dirname
    : path.dirname(fileURLToPath(import.meta.url));

// More info at: https://storybook.js.org/docs/next/writing-tests/integrations/vitest-addon
export default defineConfig(({ command }) => ({
  plugins: [
    preact(),
    // Only lint in the dev server; vite-plugin-eslint's transform hook can crash
    // ("f is not a function") when run under non-dev-server builds like
    // `storybook build`, since its filter is only wired up in a dev buildStart hook.
    // Real lint enforcement runs separately via `npm run eslint-check`.
    command === "serve" ? eslint() : undefined,
    svgr({
      svgrOptions: {
        icon: true,
      },
    }),
  ],
  build: {
    manifest: true,
    outDir: "../build-webapp",
    emptyOutDir: true,
  },
  server: {
    strictPort: true,
  },
  test: {
    workspace: [
      {
        extends: true,
        plugins: [
          // The plugin will run tests for the stories defined in your Storybook config
          // See options at: https://storybook.js.org/docs/next/writing-tests/integrations/vitest-addon#storybooktest
          storybookTest({
            configDir: path.join(dirname, ".storybook"),
          }),
        ],
        test: {
          name: "storybook",
          browser: {
            enabled: true,
            headless: true,
            provider: "playwright",
            instances: [
              {
                browser: "chromium",
              },
            ],
          },
        },
      },
    ],
  },
}));
