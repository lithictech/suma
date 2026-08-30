import { RoutePath, untypedRoutePath, UntypedRoutePath } from "../routing/RoutePath.ts";
import Alert from "../ui/Alert.tsx";
import Button from "../ui/Button";
import ButtonGroup from "../ui/ButtonGroup";
import Icon from "../ui/Icon.tsx";
import Stack from "../ui/Stack";
import { DemoStack } from "./helpers.tsx";
import { ShoppingBagIcon } from "@heroicons/react/24/outline";
import ChevronRightIcon from "@heroicons/react/24/outline/ChevronRightIcon";
import type { Meta, StoryObj } from "@storybook/preact-vite";
import React from "react";

const meta = {
  title: "Styleguide/Alerts",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const Variants: Story = {
  render: () => (
    <DemoStack>
      <Alert text="Something terrible has happened!" variant="danger" />
      <Alert text="Something great has happened!" variant="success" />
      <Alert title="This also has a title" text="Something terrible has happened!" />
      <Alert title="This only has a title" variant="secondary" />
      <Alert title="This has a custom icon" icon={ShoppingBagIcon} />
      <Alert
        title="This goes somewhere"
        text="Check the hash."
        to={untypedRoutePath("#hello")}
      />
    </DemoStack>
  ),
};
