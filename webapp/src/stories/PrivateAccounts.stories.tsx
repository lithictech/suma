import PrivateAccountDetail, {
  PrivateAccountDetailApiCalls,
} from "../components/PrivateAccountDetail.tsx";
import PrivateAccountsList from "../components/PrivateAccountsList.tsx";
import { anonProxyVendorAccount, axiosResponse, currentMember } from "./fixtures.ts";
import type { Meta, StoryObj } from "@storybook/preact-vite";
import { AxiosResponse } from "axios";
import noop from "lodash/noop";

const meta = {
  title: "Styleguide/PrivateAccounts",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const AccountsList: Story = {
  render: () => (
    <PrivateAccountsList
      accounts={[
        anonProxyVendorAccount({ indexCardMode: "link" }),
        anonProxyVendorAccount({ indexCardMode: "relink" }),
        anonProxyVendorAccount({
          indexCardMode: "payment",
          helpText:
            "In the real app, this help text can be Markdown with normal behavior.",
        }),
      ]}
    />
  ),
};

export const EmptyAccountsList: Story = {
  render: () => <PrivateAccountsList accounts={[]} />,
};

export const ReconnectAccount: Story = {
  render: () => (
    <PrivateAccountDetail
      user={currentMember()}
      setUser={noop}
      id={1}
      apiCalls={makeApiCalls({ accounts: [anonProxyVendorAccount()] })}
    />
  ),
};

interface BuildApiCallsParams {
  accounts?: AnonProxyVendorAccount[];
  charges?: CurrentMember[];
  polls?: AnonProxyVendorAccountPollResult[];
  auths?: AnonProxyVendorAccount[];
}

function makeApiCalls(params: BuildApiCallsParams): PrivateAccountDetailApiCalls {
  const indexes: Record<keyof BuildApiCallsParams, number> = {
    accounts: 0,
    charges: 0,
    polls: 0,
    auths: 0,
  };
  function makeCall<T>(k: keyof BuildApiCallsParams): () => Promise<AxiosResponse<T>> {
    return () => {
      const arr = params[k];
      if (!arr || arr.length === 0) {
        throw new Error(`made api call to ${k} but no responses configured`);
      }
      const idx = indexes[k] % arr.length;
      const val = arr[idx] as T;
      indexes[k]++;
      return Promise.resolve(axiosResponse(val));
    };
  }
  return {
    processAccount: makeCall("accounts"),
    chargeLedgerBalance: makeCall("charges"),
    pollForNewPrivateAccountMagicLink: makeCall("polls"),
    makeAuthRequest: makeCall("auths"),
  };
}
