import "../src/assets/styles/imports";
import i18n from "../src/localization/i18n";
import { installPromiseExtras } from "../src/modules/bluejay.ts";
import ScreenLoaderProvider from "../src/state/ScreenLoaderProvider.tsx";
import type { Preview } from "@storybook/preact-vite";
import { MemoryRouter } from "react-router-dom";

installPromiseExtras(window.Promise);

// Load real, already-formatted strings so stories show localized text instead of
// raw keys. In local dev there's no API running alongside Storybook, so default to
// production; the built static output is always served same-origin with the API
// (see bin/build-storybook), so that build sets VITE_STORYBOOK_API_HOST to "" for
// a relative request instead. If the request fails, stories just show placeholder keys.
const staticStringsHost =
  import.meta.env.VITE_STORYBOOK_API_HOST ?? "https://app.mysuma.org";

(async () => {
  try {
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), 5000);
    const resp = await fetch(
      `${staticStringsHost}/api/v1/meta/static_strings/en/strings`,
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
