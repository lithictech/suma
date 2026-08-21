import Card from "../ui/Card";
import CardBody from "../ui/CardBody";
import DefinitionTable from "../ui/DefinitionTable.tsx";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Tables",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const Definition: Story = {
  render: () => (
    <Card>
      <CardBody>
        <DefinitionTable
          items={[
            { label: "Much Longer Field Name", value: "Ana Flores" },
            {
              label: "Eligibility",
              value: <span>Hacienda CDC &bull; In Review</span>,
            },
            {
              label: "Address",
              value:
                "2001 NE Alberta St, Portland, OR 97211 2001 NE Alberta St, Portland, OR 97211",
            },
          ]}
        />
      </CardBody>
    </Card>
  ),
};
