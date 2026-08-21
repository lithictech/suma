import BreadcrumbBack from "../ui/BreadcrumbBack.tsx";
import ProgressStepHeader from "../ui/ProgressStepHeader.tsx";
import { DemoStack } from "./helpers.tsx";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Headers",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const ProgressSteps: Story = {
  render: () => (
    <DemoStack>
      <ProgressStepHeader step={1} steps={5} />
      <ProgressStepHeader step={4} steps={5} />
      <ProgressStepHeader step={5} steps={5} />
    </DemoStack>
  ),
};

export const Breadcrumbs: Story = {
  render: () => (
    <DemoStack>
      <div>
        <BreadcrumbBack back />
      </div>
    </DemoStack>
  ),
};
