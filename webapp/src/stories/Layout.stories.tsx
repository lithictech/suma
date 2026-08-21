import Card from "../ui/Card";
import CardBody from "../ui/CardBody";
import Grid from "../ui/Grid.tsx";
import type { Meta, StoryObj } from "@storybook/preact-vite";

function GridDemo({
  columnCount,
  columnSize,
}: {
  columnCount?: number;
  columnSize?: string;
}) {
  return (
    <Grid columns={columnCount || columnSize}>
      {[1, 2, 3, 4, 5].map((i) => (
        <Card key={i}>
          <CardBody>
            <p>Hello</p>
          </CardBody>
        </Card>
      ))}
    </Grid>
  );
}

const meta = {
  title: "Styleguide/Layout",
  component: GridDemo,
  argTypes: {
    columnCount: { control: "number" },
    columnSize: { control: "text", description: "8rem, etc." },
  },
} satisfies Meta<typeof GridDemo>;

export default meta;
type Story = StoryObj<typeof meta>;

export const GridNumericColumns: Story = {
  args: { columnCount: 3 },
  parameters: { controls: { exclude: ["columnSize"] } },
};

export const GridSizedColumns: Story = {
  args: { columnCount: 0, columnSize: "8rem" },
  parameters: { controls: { exclude: ["columnCount"] } },
};
