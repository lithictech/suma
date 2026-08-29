import LanguageSwitcher from "../ui/LanguageSwitcher.tsx";
import ThemeSwitcher from "../ui/ThemeSwitcher.tsx";
import { DemoStack } from "./helpers.tsx";
import type { Meta, StoryObj } from "@storybook/preact-vite";
import React from "react";

const meta = {
  title: "Styleguide/Presentation",
} satisfies Meta<typeof meta>;

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
    // eslint-disable-next-line react-hooks/rules-of-hooks
    const [language, setLanguage] = React.useState("en");
    return (
      <DemoStack>
        <LanguageSwitcher
          supportedLocales={[
            { code: "en", language: "English", native: "English" },
            { code: "es", language: "Spanish", native: "Español" },
          ]}
          currentLanguage={language}
          changeLanguage={setLanguage}
        />
      </DemoStack>
    );
  },
};
