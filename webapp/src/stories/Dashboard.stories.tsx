import Dashboard from "../components/Dashboard.tsx";
import { floatToMoney } from "../modules/money.ts";
import Page from "../ui/Page.tsx";
import { currentMember, mobilityTrip, program } from "./fixtures.ts";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Dashboard",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const Empty: Story = {
  render: () => (
    <Page>
      <Dashboard
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
      <Dashboard
        loading={false}
        error={null}
        dashboard={{
          ...dashboard,
          programs: [
            program({
              name: "Group purchase: Tails & Trotters CSA Box",
              description: "Available for a limited time",
              periodBegin: "2024-01-01T12:00:00Z",
              periodEnd: "2024-03-01T12:00:00Z",
            }),
            program({
              name: "Group purchase: Tails & Trotters CSA Box",
              description: "Available for a limited time",
              periodBegin: "2024-01-01T12:00:00Z",
              periodEnd: "2024-03-01T12:00:00Z",
              appLink: "/food",
              appLinkText: "Link to an action",
            }),
          ],
        }}
        user={currentMember()}
      />
    </Page>
  ),
};

export const Alerts: Story = {
  render: () => (
    <Page>
      <Dashboard
        loading={false}
        error={null}
        dashboard={{
          ...dashboard,
          alerts: [
            {
              localizationKey: "dashboard.negative_cash_balance_v2",
              localizationParams: {
                amount: {
                  cents: 456,
                  currency: "USD",
                },
              },
              variant: "danger",
            },
            {
              localizationKey: "dashboard.payment_methods_expiring",
              localizationParams: {},
              variant: "warning",
            },
            {
              localizationKey: "dashboard.negative_cash_balance_no_instrument",
              localizationParams: {},
              variant: "danger",
            },
          ],
        }}
        user={currentMember({
          ongoingTrip: mobilityTrip(),
          readOnlyReason: "",
          unclaimedOrdersCount: 1,
          registrationLink: {
            organizationName: "Housing Co",
            intro: "",
          },
        })}
      />
    </Page>
  ),
};

export const Savings: Story = {
  render: () => (
    <Page>
      <Dashboard
        loading={false}
        error={null}
        dashboard={{
          ...dashboard,
          lifetimeSavings: floatToMoney(362.6, "USD"),
          lifetimeCashPaid: floatToMoney(88.4, "USD"),
          lifetimeSavingsRatio: 80,
        }}
        user={currentMember()}
      />
    </Page>
  ),
};

const dashboard: Dashboard = {
  cashBalance: floatToMoney(0, "USD"),
  lifetimeSavings: floatToMoney(0, "USD"),
  lifetimeCashPaid: floatToMoney(0, "USD"),
  lifetimeSavingsRatio: 75,
  programs: [],
  alerts: [],
};
