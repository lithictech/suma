import Progress from "../ui/Progress";
import Stack from "../ui/Stack";
import { DemoStack } from "./helpers.tsx";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Progress",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const Bar: Story = {
  render: () => (
    <DemoStack>
      <Progress value={0} />
      <Progress value={37} />
      <Progress value={50} />
      <Progress value={96} />
      <Progress value={100} />
    </DemoStack>
  ),
};

export const Circle: Story = {
  render: () => (
    <DemoStack>
      <Progress variant="circle" value={0} />
      <Progress variant="circle" value={37} />
      <Progress variant="circle" value={50} />
      <Progress variant="circle" value={96} />
      <Progress variant="circle" value={100} />
    </DemoStack>
  ),
};
