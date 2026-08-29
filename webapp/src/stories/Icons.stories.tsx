import Button from "../ui/Button.tsx";
import Icon, { IconPropsIcon } from "../ui/Icon.tsx";
import IconChip from "../ui/IconChip.tsx";
import { DemoStack } from "./helpers.tsx";
import LanguageIcon from "@heroicons/react/24/outline/LanguageIcon";
import MapIcon from "@heroicons/react/24/outline/MapIcon";
import MapPinIcon from "@heroicons/react/24/outline/MapPinIcon";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const meta = {
  title: "Styleguide/Icons",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

const icons: IconPropsIcon[] = [LanguageIcon, MapIcon, MapPinIcon, "right", "left"];
const colors = ["primary", "secondary", "success", "danger"];

export const Icons: Story = {
  render: () => {
    return (
      <DemoStack>
        <h2>Icons</h2>
        <DemoStack row>
          {icons.map((ic, i) => (
            <Icon key={i} icon={ic} />
          ))}
        </DemoStack>
        <h2>Buttons</h2>
        <DemoStack row>
          {icons.map((ic, i) => (
            <Button key={i}>
              <Icon icon={ic} />
            </Button>
          ))}
        </DemoStack>
        <DemoStack row>
          {icons.map((ic, i) => (
            <Button key={i} variant="text">
              <Icon icon={ic} />
            </Button>
          ))}
        </DemoStack>
      </DemoStack>
    );
  },
};

export const Chips: Story = {
  render: () => (
    <DemoStack row>
      {icons.map((ic, i) => (
        <div key={i}>
          <IconChip
            size={10 * (1 + i / 2)}
            icon={ic}
            color={colors[i % colors.length] as any}
          />
        </div>
      ))}
      <IconChip size={48} icon={icons[0]} color="success" />
    </DemoStack>
  ),
};
