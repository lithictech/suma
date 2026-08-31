import DashboardC from "../components/Dashboard.tsx";
import { floatToMoney } from "../modules/money.ts";
import Page from "../ui/Page.tsx";
import { currentMember } from "./fixtures.ts";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Dashboard",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const Empty: Story = {
  render: () => (
    <Page>
      <DashboardC
        loading={false}
        error={null}
        dashboard={dashboard}
        user={currentMember()}
      />
    </Page>
  ),
};

export const Programs: Story = {
  render: () => (
    <Page>
      <DashboardC
        loading={false}
        error={null}
        dashboard={dashboard}
        user={currentMember()}
      />
    </Page>
  ),
};

export const Alerts: Story = {
  render: () => (
    <Page>
      <DashboardC
        loading={false}
        error={null}
        dashboard={dashboard}
        user={currentMember()}
      />
    </Page>
  ),
};

const dashboard: Dashboard = {
  cashBalance: floatToMoney(0, "USD"),
  programs: [],
  alerts: [],
};
