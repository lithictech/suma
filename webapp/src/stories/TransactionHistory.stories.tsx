import TransactionHistory from "../components/TransactionHistory.tsx";
import { AppError } from "../modules/feedback.ts";
import {
  apiCollection,
  axiosResponse,
  ledgerLine,
  ledgerLineOrder,
  ledgerLineTrip,
  ledgersOverview,
  money,
} from "./fixtures.ts";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/TransactionHistory",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const RecentHistory: Story = {
  render: () => (
    <TransactionHistory
      params={new URLSearchParams()}
      page={0}
      ledgersOverview={ledgersOverview({
        recentLines: [ledgerLine(), ledgerLineTrip(), ledgerLineOrder()],
      })}
      getLedgerLines={() =>
        Promise.resolve(
          axiosResponse<LedgerLines>({
            ...apiCollection<LedgerLine>([]),
            ledgerId: 0,
          })
        )
      }
    />
  ),
};

export const EmptyHistory: Story = {
  render: () => (
    <TransactionHistory
      params={new URLSearchParams()}
      page={0}
      ledgersOverview={ledgersOverview()}
      getLedgerLines={() =>
        Promise.resolve(
          axiosResponse<LedgerLines>({ ...apiCollection<LedgerLine>([]), ledgerId: 0 })
        )
      }
    />
  ),
};

export const OverviewLoading: Story = {
  render: () => (
    <TransactionHistory
      params={new URLSearchParams()}
      page={0}
      loading
      ledgersOverview={ledgersOverview()}
      getLedgerLines={() =>
        Promise.resolve(
          axiosResponse<LedgerLines>({ ...apiCollection<LedgerLine>([]), ledgerId: 0 })
        )
      }
    />
  ),
};

export const OverviewError: Story = {
  render: () => (
    <TransactionHistory
      params={new URLSearchParams()}
      page={0}
      error={new AppError("", {}, "Error while loading ledgers.")}
      ledgersOverview={ledgersOverview()}
      getLedgerLines={() =>
        Promise.resolve(
          axiosResponse<LedgerLines>({ ...apiCollection<LedgerLine>([]), ledgerId: 0 })
        )
      }
    />
  ),
};
