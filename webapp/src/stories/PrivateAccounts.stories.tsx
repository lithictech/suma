import PrivateAccountsList from "../components/PrivateAccountsList.tsx";
import { untypedRoutePath } from "../routing/RoutePath.ts";
import Alert from "../ui/Alert.tsx";
import { anonProxyVendorAccount } from "./fixtures.ts";
import { DemoStack } from "./helpers.tsx";
import { ShoppingBagIcon } from "@heroicons/react/24/outline";
import type { Meta, StoryObj } from "@storybook/preact-vite";

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
