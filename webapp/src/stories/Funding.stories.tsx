import AddCreditCard from "../components/AddCreditCard.tsx";
import Funding from "../components/Funding.tsx";
import {
  axiosResponse,
  bankAccount,
  currentMember,
  paymentInstrument,
} from "./fixtures.ts";
import { fakeNavigate } from "./fixtures.ts";
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

export const AddCard: Story = {
  render: () => (
    <AddCreditCard
      user={currentMember()}
      onSubmit={handleAddCardSubmit}
      handleUpdateCurrentMember={noop}
      navigate={fakeNavigate}
    />
  ),
};

const handleAddCardSubmit = () => {
  const resp: MutationPaymentInstrument = {
    ...paymentInstrument(),
    allPaymentInstruments: [],
  };
  return Promise.resolve(axiosResponse(resp));
};

export const AddCardWithStub: Story = {
  render: () => (
    <AddCreditCard
      user={currentMember()}
      onSubmit={handleAddCardSubmit}
      handleUpdateCurrentMember={noop}
      navigate={fakeNavigate}
      stubData={stubData}
    />
  ),
};

const stubData = {
  name: "Jose G",
  number: "4242424242424242",
  expiry: "12/99",
  cvc: "123",
};

export const AddCardWithReturn: Story = {
  render: () => (
    <AddCreditCard
      user={currentMember()}
      onSubmit={handleAddCardSubmit}
      handleUpdateCurrentMember={noop}
      navigate={fakeNavigate}
      stubData={stubData}
      returnTo="#somewhere-else"
    />
  ),
};

export const AddCardWithImmediateReturn: Story = {
  render: () => (
    <AddCreditCard
      user={currentMember()}
      onSubmit={handleAddCardSubmit}
      handleUpdateCurrentMember={noop}
      navigate={fakeNavigate}
      stubData={stubData}
      returnToImmediate="#somewhere-else"
    />
  ),
};

export const AddCardSuccess: Story = {
  render: () => (
    <AddCreditCard
      user={currentMember()}
      onSubmit={handleAddCardSubmit}
      handleUpdateCurrentMember={noop}
      navigate={fakeNavigate}
      stubCreatedInstrument={paymentInstrument()}
    />
  ),
};
