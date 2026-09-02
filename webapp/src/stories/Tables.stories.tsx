import Card from "../ui/Card";
import CardBody from "../ui/CardBody";
import DefinitionTable from "../ui/DefinitionTable.tsx";
import Table from "../ui/Table.tsx";
import TableBody from "../ui/TableBody.tsx";
import TableFooter from "../ui/TableFooter.tsx";
import TableHeader from "../ui/TableHeader.tsx";
import TableHeaders from "../ui/TableHeaders.tsx";
import TableRow from "../ui/TableRow.tsx";
import { DemoStack } from "./helpers.tsx";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Tables",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const Standard: Story = {
  render: () => {
    const children = (
      <>
        <TableHeaders cells={["Person", "Most interest in", "Age"]} />
        <TableBody>
          <TableRow
            cells={[
              <TableHeader key={1} row>
                Chris
              </TableHeader>,
              <strong key={2}>HTML tables</strong>,
              "22",
            ]}
          />
          <TableRow cells={["Dennis", "Web accessibility", "45"]} />
          <TableRow
            cells={[
              <TableHeader key={1} row colSpan={2}>
                Sarah
              </TableHeader>,
              "29",
            ]}
          />
          <TableRow cells={["Karen", "Web performance", "36"]} />
        </TableBody>
        <TableFooter
          cells={[{ colSpan: 2, className: "text-right", children: "Average age" }, "33"]}
        />
      </>
    );
    return (
      <DemoStack>
        <Table caption="Default">{children}</Table>
        <hr />
        <Table caption="Compact/Hover" compact hover>
          {children}
        </Table>
        <hr />
        <Table caption="Striped/Hover" striped hover>
          {children}
        </Table>
        <hr />
        <Table caption="Small/Borderless" size="sm" borders={false}>
          {children}
        </Table>
        <hr />
        <Table
          caption="Large/Themed"
          size="lg"
          striped
          hover
          theme={{
            headerColor: "var(--tint-secondary)",
            backgroundColor1: "var(--tint-alert)",
            backgroundColor2: "var(--tint-success)",
            hoverColor: "var(--tint-primary)",
          }}
        >
          {children}
        </Table>
      </DemoStack>
    );
  },
};

export const Definition: Story = {
  render: () => (
    <DemoStack>
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
    </DemoStack>
  ),
};
