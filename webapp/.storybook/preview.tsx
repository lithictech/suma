import "../src/assets/styles/imports";
import i18n from "../src/localization/i18n";
import { installPromiseExtras } from "../src/modules/bluejay.ts";
import ScreenLoaderProvider from "../src/state/ScreenLoaderProvider.tsx";
import type { Preview } from "@storybook/preact-vite";
import { MemoryRouter } from "react-router-dom";

installPromiseExtras(window.Promise);

// Load real, already-formatted strings from production so stories show localized
// text instead of raw keys. If production is unreachable, stories just fall back
// to placeholder keys.
(async () => {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);
    const resp = await fetch(
      "https://app.mysuma.org/api/v1/meta/static_strings/en/strings",
      { signal: controller.signal }
    );
    clearTimeout(timeout);
    if (resp.ok) {
      i18n.putFile("en", "strings", await resp.json());
    }
  } catch {
    // API unreachable; stories will show untranslated placeholders.
  }
})();
i18n.language = "en";
i18n.addFormatters();

const preview: Preview = {
  decorators: [
    (Story) => (
      <MemoryRouter>
        <ScreenLoaderProvider>
          <Story />
        </ScreenLoaderProvider>
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
