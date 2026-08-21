import { DemoStack } from "./helpers.tsx";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Typography",
} satisfies Meta<typeof meta>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Headers: Story = {
  render: () => (
    <DemoStack>
      <h1>H1 Heading</h1>
      <h2>H2 Heading</h2>
      <h3>H3 Heading</h3>
      <h4>H4 Heading</h4>
      <h5>H5 Heading</h5>
      <h6>H6 Heading</h6>
    </DemoStack>
  ),
};

export const Text: Story = {
  render: () => (
    <DemoStack>
      <p>
        Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras sed ligula blandit,
        dictum massa quis, lobortis metus. Nunc ac justo nec ante tincidunt euismod ut vel
        libero. <a href="#">Sed gravida porta malesuada.</a> Sed iaculis pretium urna vel
        elementum. Sed vel egestas nisi, eget molestie diam. Vivamus urna elit, elementum
        ut justo et, cursus interdum tortor. Proin suscipit ac neque sit amet iaculis. In
        ut erat in mauris feugiat ornare. Sed condimentum non enim ut lacinia. Fusce ac
        libero cursus magna vulputate rutrum. Nullam dapibus enim eu facilisis cursus.
        Mauris vel est a lacus venenatis sollicitudin et eget turpis. Lorem ipsum dolor
        sit amet, consectetur adipiscing elit. Nunc at viverra tellus. Nunc vitae nulla
        nisl.
      </p>
    </DemoStack>
  ),
};
