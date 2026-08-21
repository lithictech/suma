import { RoutePath } from "../routing/RoutePath.ts";
import Nav from "../ui/Nav.tsx";
import NavOption from "../ui/NavOption.tsx";
import { DemoStack } from "./helpers.tsx";
import BuildingStorefrontIcon from "@heroicons/react/24/outline/BuildingStorefrontIcon";
import HomeIcon from "@heroicons/react/24/outline/HomeIcon";
import ShoppingCartIcon from "@heroicons/react/24/outline/ShoppingCartIcon";
import SquaresPlusIcon from "@heroicons/react/24/outline/SquaresPlusIcon";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Nav",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const Navigation: Story = {
  render: () => (
    <DemoStack>
      <Nav>
        <NavOption label="Home" Icon={HomeIcon} to={"#" as RoutePath} />
        <NavOption
          label="Offers"
          Icon={BuildingStorefrontIcon}
          active
          to={"#" as RoutePath}
        />
        <NavOption label="Map" Icon={ShoppingCartIcon} to={"#" as RoutePath} />
        <NavOption label="More" Icon={SquaresPlusIcon} to={"#" as RoutePath} />
      </Nav>
    </DemoStack>
  ),
};
