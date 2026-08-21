import Chip from "../ui/Chip";
import Stack from "../ui/Stack";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Chips",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const Variants: Story = {
  render: () => (
    <Stack gap={2}>
      <Chip variant="secondary">Available now</Chip>
      <Chip variant="info">Ready for pickup</Chip>
      <Chip variant="danger">2 left</Chip>
      <Chip variant="success">Picked up</Chip>
    </Stack>
  ),
};
