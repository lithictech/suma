import Chip from "../ui/Chip";
import { themeColors } from "./constants.tsx";
import { DemoStack } from "./helpers.tsx";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Chips",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const Variants: Story = {
  render: () => (
    <DemoStack className="align-items-start">
      <h2>Chips</h2>
      {themeColors.map((c) => (
        <Chip key={c} variant={c}>
          {c}
        </Chip>
      ))}
      <h2>Invert</h2>
      {themeColors.map((c) => (
        <Chip key={c} variant={c} invert>
          {c}
        </Chip>
      ))}
      <h2>Bullets</h2>
      {themeColors.map((c) => (
        <Chip key={c} variant={c} bullet>
          {c}
        </Chip>
      ))}
    </DemoStack>
  ),
};
