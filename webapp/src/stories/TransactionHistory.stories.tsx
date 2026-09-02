import TransactionHistory from "../components/TransactionHistory.tsx";
import { AppError } from "../modules/feedback.ts";
import useHashSelector from "../state/useHashSelector.ts";
import useLazyRef from "../state/useLazyRef.ts";
import useMountEffect from "../state/useMountEffect.ts";
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

const defaultLedger = ledger();

export const RecentHistory: Story = {
  render: () => (
    <TransactionHistory
      ledgerLinesPage={0}
      ledgersOverview={ledgersOverview({
        recentLines: [
          ledgerLine(defaultLedger.id),
          ledgerLineTrip(defaultLedger.id),
          ledgerLineOrder(defaultLedger.id),
        ],
        ledgers: [],
      })}
      getLedgerLines={axiosResponseMocker<LedgerLines>({
        ...apiCollection<LedgerLine>([]),
        ledgerId: defaultLedger.id,
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
      [led1.id + ""]: [ledgerLine(led1.id), ledgerLineTrip(led1.id)],
      [led2.id + ""]: [
        ledgerLineOrder(led2.id),
        ledgerLine(led2.id),
        ledgerLineTrip(led2.id),
        ledgerLineOrder(led2.id),
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

export const ViewingDetail: Story = {
  render: () => {
    const led = useLazyRef(ledger);
    const line = useLazyRef(() => ledgerLineTrip(led.id));
    const { selectHashItem } = useHashSelector([line], "opaqueId");
    useMountEffect(() => {
      selectHashItem(line);
    });
    return (
      <TransactionHistory
        ledgerLinesPage={0}
        ledgersOverview={ledgersOverview({
          recentLines: [ledgerLine(led.id), line, ledgerLineOrder(led.id)],
          ledgers: [led],
        })}
        getLedgerLines={axiosResponseMocker<LedgerLines>({
          ...apiCollection<LedgerLine>([]),
          ledgerId: 0,
        })}
        ledgerId={0}
        setLedgerId={noop}
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
