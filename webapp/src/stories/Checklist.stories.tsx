import Checklist from "../ui/Checklist";
import ChecklistItem from "../ui/ChecklistItem";
import { DemoStack } from "./helpers.tsx";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Checklist",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  render: () => (
    <DemoStack>
      <Checklist>
        <ChecklistItem variant="checked">How it works</ChecklistItem>
        <ChecklistItem variant="checked">Agree</ChecklistItem>
        <ChecklistItem variant="current">Get text</ChecklistItem>
        <ChecklistItem>Get link</ChecklistItem>
        <ChecklistItem step={20}>Explicit step</ChecklistItem>
      </Checklist>
    </DemoStack>
  ),
};
