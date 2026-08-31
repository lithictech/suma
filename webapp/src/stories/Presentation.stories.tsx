import LanguageSwitcher from "../ui/LanguageSwitcher.tsx";
import ThemeSwitcher from "../ui/ThemeSwitcher.tsx";
import { DemoStack } from "./helpers.tsx";
import type { Meta, StoryObj } from "@storybook/preact-vite";
import React from "react";

const meta = {
  title: "Styleguide/Presentation",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const Theme: Story = {
  render: () => (
    <DemoStack>
      <ThemeSwitcher />
    </DemoStack>
  ),
};

export const Language: Story = {
  render: () => {
    const supported = [
      { code: "en", language: "English", native: "English" },
      { code: "es", language: "Spanish", native: "Español" },
    ];
    const [language, setLanguage] = React.useState("en");
    return (
      <DemoStack>
        <LanguageSwitcher
          supportedLocales={supported}
          currentLanguage={language}
          changeLanguage={setLanguage}
          variant="horizontal"
        />
        <LanguageSwitcher
          supportedLocales={supported}
          currentLanguage={language}
          changeLanguage={setLanguage}
          variant="vertical"
        />
        <LanguageSwitcher
          supportedLocales={supported}
          currentLanguage={language}
          changeLanguage={setLanguage}
          variant="short"
        />
      </DemoStack>
    );
  },
};
