import ProgramCard from "../components/ProgramCard.tsx";
import { program } from "./fixtures.ts";
import { DemoStack } from "./helpers.tsx";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Programs",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const ProgramCards: Story = {
  render: () => (
    <DemoStack>
      <ProgramCard {...program()} />
    </DemoStack>
  ),
};
