import "../src/assets/styles/imports";
import { installPromiseExtras } from "../src/modules/bluejay.ts";
import type { Preview } from "@storybook/preact-vite";
import React from "react";
import { MemoryRouter } from "react-router-dom";

installPromiseExtras(window.Promise);

const preview: Preview = {
  decorators: [
    (Story) => (
      <MemoryRouter>
        <Story />
      </MemoryRouter>
    ),
  ],
  parameters: {
    controls: {
      matchers: {
        color: /(background|color)$/i,
        date: /Date$/i,
      },
    },

    a11y: {
      // 'todo' - show a11y violations in the test UI only
      // 'error' - fail CI on a11y violations
      // 'off' - skip a11y checks entirely
      test: "todo",
    },
  },
};

export default preview;
