import Checklist from "../ui/Checklist";
import ChecklistItem from "../ui/ChecklistItem";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Checklist",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  render: () => (
    <Checklist>
      <ChecklistItem variant="checked">How it works</ChecklistItem>
      <ChecklistItem variant="checked">Agree</ChecklistItem>
      <ChecklistItem variant="current" step={3}>
        Get text
      </ChecklistItem>
      <ChecklistItem step={4}>Get link</ChecklistItem>
      <ChecklistItem step={5}>Finish linking</ChecklistItem>
    </Checklist>
  ),
};
