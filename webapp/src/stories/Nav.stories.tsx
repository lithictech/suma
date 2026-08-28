import { RoutePath } from "../routing/RoutePath.ts";
import Nav from "../ui/Nav.tsx";
import NavOption from "../ui/NavOption.tsx";
import Page from "../ui/Page.tsx";
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

export const WithShortContent: Story = {
  render: () => (
    <Page
      style={{
        maxWidth: 200,
        border: "1px solid black",
        overflow: "hidden",
      }}
    >
      <Page buffer gap={2}>
        <div>
          The nav menu should sit at the bottom of the page, within the buffer supplied by
          Storybook. This main area should fill the visual area, but NOT push the content
          below the bottom of the screen, which would normally happen if the nav content
          is simply sticky, and the main viewport is 100vh without biasing by the nav
          height.
        </div>
      </Page>
      <Nav>
        <NavOption label="Home" Icon={HomeIcon} to={"#" as RoutePath} />
      </Nav>
    </Page>
  ),
};

export const WithLongContent: Story = {
  render: () => (
    <Page
      style={{
        maxWidth: 200,
        border: "1px solid black",
        overflow: "hidden",
      }}
    >
      <Page buffer gap={2}>
        <div>
          Test that the content that overflows the screen can be seen while scrolling.
        </div>
        <div>Keep going until you see the end!</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>Keep going...</div>
        <div>YOU MADE IT!</div>
      </Page>
      <Nav>
        <NavOption label="Home" Icon={HomeIcon} to={"#" as RoutePath} />
      </Nav>
    </Page>
  ),
};
