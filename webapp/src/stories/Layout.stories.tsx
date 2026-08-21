import Card from "../ui/Card";
import CardBody from "../ui/CardBody";
import Grid from "../ui/Grid.tsx";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Layout",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const FixedColumns: Story = {
  render: () => (
    <Grid columns={2}>
      {[1, 2, 3].map((i) => (
        <Card key={i}>
          <CardBody>
            <p>Hello</p>
          </CardBody>
        </Card>
      ))}
    </Grid>
  ),
};

export const ResponsiveColumns: Story = {
  render: () => (
    <Grid columns="8rem">
      {[1, 2, 3, 4, 5].map((i) => (
        <Card key={i}>
          <CardBody>
            <p>Hello</p>
          </CardBody>
        </Card>
      ))}
    </Grid>
  ),
};
