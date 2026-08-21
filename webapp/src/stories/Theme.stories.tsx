import ThemeSwitcher from "../ui/ThemeSwitcher.tsx";
import { DemoStack } from "./helpers.tsx";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Theme",
} satisfies Meta<typeof meta>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  render: () => (
    <DemoStack>
      <ThemeSwitcher />
    </DemoStack>
  ),
};
