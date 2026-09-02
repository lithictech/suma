import TransactionHistory from "../components/TransactionHistory.tsx";
import { AppError } from "../modules/feedback.ts";
import useLazyRef from "../state/useLazyRef.ts";
import {
  apiCollection,
  axiosResponse,
  axiosResponseMocker,
  ledger,
  ledgerLine,
  ledgerLineOrder,
  ledgerLineTrip,
  ledgersOverview,
} from "./fixtures.ts";
import type { Meta, StoryObj } from "@storybook/preact-vite";
import noop from "lodash/noop";
import React from "react";

const meta = {
  title: "Styleguide/TransactionHistory",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const RecentHistory: Story = {
  render: () => (
    <TransactionHistory
      ledgerLinesPage={0}
      ledgersOverview={ledgersOverview({
        recentLines: [ledgerLine(), ledgerLineTrip(), ledgerLineOrder()],
        ledgers: [],
      })}
      getLedgerLines={axiosResponseMocker<LedgerLines>({
        ...apiCollection<LedgerLine>([]),
        ledgerId: 0,
      })}
      ledgerId={0}
      setLedgerId={noop}
      setLedgerLinesPage={noop}
    />
  ),
};

export const EmptyHistory: Story = {
  render: () => (
    <TransactionHistory
      ledgerLinesPage={0}
      ledgersOverview={ledgersOverview()}
      getLedgerLines={() =>
        Promise.resolve(
          axiosResponse<LedgerLines>({ ...apiCollection<LedgerLine>([]), ledgerId: 0 })
        )
      }
      ledgerId={0}
      setLedgerId={noop}
      setLedgerLinesPage={noop}
    />
  ),
};

export const SwitchingLedgers: Story = {
  render: () => {
    const led1 = useLazyRef(() => ledger({ name: "Mobility" }));
    const led2 = useLazyRef(() => ledger({ name: "Food" }));
    const ledgerLines = useLazyRef(() => ({
      [led1.id + ""]: [ledgerLine(), ledgerLineTrip()],
      [led2.id + ""]: [
        ledgerLineOrder(),
        ledgerLine(),
        ledgerLineTrip(),
        ledgerLineOrder(),
      ],
    }));
    const [ledgerId, setLedgerId] = React.useState(led1.id);
    return (
      <TransactionHistory
        ledgerLinesPage={0}
        ledgersOverview={ledgersOverview({
          recentLines: [],
          ledgers: [led1, led2],
        })}
        getLedgerLines={axiosResponseMocker<LedgerLines>({
          ...apiCollection<LedgerLine>(ledgerLines[ledgerId || ""]),
          ledgerId: ledgerId,
        })}
        ledgerId={ledgerId}
        setLedgerId={setLedgerId}
        setLedgerLinesPage={noop}
      />
    );
  },
};

export const OverviewLoading: Story = {
  render: () => (
    <TransactionHistory
      loading
      ledgerLinesPage={0}
      ledgersOverview={ledgersOverview()}
      getLedgerLines={() =>
        Promise.resolve(
          axiosResponse<LedgerLines>({ ...apiCollection<LedgerLine>([]), ledgerId: 0 })
        )
      }
      ledgerId={0}
      setLedgerId={noop}
      setLedgerLinesPage={noop}
    />
  ),
};

export const OverviewError: Story = {
  render: () => (
    <TransactionHistory
      error={new AppError("", {}, "Error while loading ledgers.")}
      ledgerLinesPage={0}
      ledgersOverview={ledgersOverview()}
      getLedgerLines={() =>
        Promise.resolve(
          axiosResponse<LedgerLines>({ ...apiCollection<LedgerLine>([]), ledgerId: 0 })
        )
      }
      ledgerId={0}
      setLedgerId={noop}
      setLedgerLinesPage={noop}
    />
  ),
};
