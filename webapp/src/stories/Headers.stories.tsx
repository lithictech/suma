import BreadcrumbBack from "../ui/BreadcrumbBack.tsx";
import ProgressStepHeader from "../ui/ProgressStepHeader.tsx";
import Stack from "../ui/Stack";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Headers",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {
  render: () => (
    <Stack gap={3} vertical>
      <div>
        <BreadcrumbBack back />
      </div>
      <ProgressStepHeader step={1} steps={5} />
      <ProgressStepHeader step={4} steps={5} />
      <ProgressStepHeader step={5} steps={5} />
    </Stack>
  ),
};
