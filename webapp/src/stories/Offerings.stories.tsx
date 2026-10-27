import TODO from "../components/TODO.tsx";
import { DemoStack } from "./helpers.tsx";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Offerings",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const OfferingLists: Story = {
  render: () => (
    <DemoStack>
      <OfferingList />
    </DemoStack>
  ),
};

export const OfferingCards: Story = {
  render: () => (
    <DemoStack>
      <OfferingCard />
    </DemoStack>
  ),
};

export const ProductCards: Story = {
  render: () => (
    <DemoStack>
      <h2>Available</h2>
      <ProductCard />
      <h2>Limited</h2>
      <ProductCard />
      <h2>Sold Out</h2>
      <ProductCard />
      <h2>Max Ordered</h2>
      <ProductCard />
      <h2>Discounted</h2>
      <ProductCard />
    </DemoStack>
  ),
};

export const ProductDetails: Story = {
  render: () => (
    <DemoStack>
      <h2>Available</h2>
      <ProductDetail />
      <h2>Limited</h2>
      <ProductDetail />
      <h2>Sold Out</h2>
      <ProductDetail />
      <h2>Max Ordered</h2>
      <ProductDetail />
      <h2>Discounted</h2>
      <ProductDetail />
    </DemoStack>
  ),
};

export const CartBars: Story = {
  render: () => (
    <DemoStack>
      <h2>Empty</h2>
      <CartBar />
      <h2>With Items</h2>
      <CartBar />
    </DemoStack>
  ),
};

const CartBar = TODO;
const ProductDetail = TODO;
const ProductCard = TODO;
const OfferingCard = TODO;
const OfferingList = TODO;
