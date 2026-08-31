import Funding from "../components/Funding.tsx";
import { bankAccount, currentMember, paymentInstrument } from "./fixtures.ts";
import type { Meta, StoryObj } from "@storybook/preact-vite";
import noop from "lodash/noop";

const meta = {
  title: "Styleguide/Funding",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const NoPaymentMethods: Story = {
  render: () => (
    <Funding
      user={currentMember()}
      setUser={noop}
      supportedPaymentMethods={["bank_account", "card"]}
      featureAddFunds={false}
    />
  ),
};

export const WithPaymentMethods: Story = {
  render: () => (
    <Funding
      user={currentMember({
        paymentInstruments: [
          paymentInstrument({ status: "unverified" }),
          paymentInstrument({ status: "ok" }),
          paymentInstrument({ status: "expired" }),

          bankAccount({ status: "unverified" }),
          bankAccount({ status: "ok" }),
          bankAccount({ status: "expired" }),
        ],
      })}
      setUser={noop}
      supportedPaymentMethods={["bank_account", "card"]}
      featureAddFunds={false}
    />
  ),
};

export const WithBalance: Story = {
  render: () => (
    <Funding
      user={currentMember({ chargeableCashBalance: { cents: -345, currency: "USD" } })}
      setUser={noop}
      supportedPaymentMethods={[]}
      featureAddFunds={false}
    />
  ),
};

export const SupportAddingFunds: Story = {
  render: () => (
    <Funding
      user={currentMember({
        paymentInstruments: [
          paymentInstrument({ status: "unverified" }),
          paymentInstrument({ status: "ok" }),
          paymentInstrument({ status: "expired" }),

          bankAccount({ status: "unverified" }),
          bankAccount({ status: "ok" }),
          bankAccount({ status: "expired" }),
        ],
      })}
      setUser={noop}
      supportedPaymentMethods={["bank_account", "card"]}
      featureAddFunds={true}
    />
  ),
};
