import Icon, { IconPropsIcon } from "../ui/Icon.tsx";
import IconButton from "../ui/IconButton.tsx";
import IconChip from "../ui/IconChip.tsx";
import { themeColors } from "./constants.tsx";
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

const icons: IconPropsIcon[] = [
  LanguageIcon,
  MapIcon,
  MapPinIcon,
  "right",
  "left",
  "loader",
  "info",
];

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
        <h3>Colored</h3>
        <DemoStack row>
          {icons.map((ic, i) => (
            <Icon key={i} icon={ic} color="danger" size={30} />
          ))}
        </DemoStack>
        <h3>Inverted</h3>
        <DemoStack row>
          {icons.map((ic, i) => (
            <Icon key={i} icon={ic} invert size={30} className="p-2" />
          ))}
        </DemoStack>
        <h2>Buttons</h2>
        <DemoStack row>
          {icons.map((ic, i) => (
            <IconButton key={i} icon={ic} />
          ))}
        </DemoStack>
        <h3>Text Variant</h3>
        <DemoStack row>
          {icons.map((ic, i) => (
            <IconButton key={i} variant="text" icon={ic} />
          ))}
        </DemoStack>
        <h3>Colored</h3>
        <DemoStack row>
          {themeColors.map((c, i) => (
            <IconButton key={i} icon="info" color={c} />
          ))}
        </DemoStack>
      </DemoStack>
    );
  },
};

export const Chips: Story = {
  render: () => (
    <DemoStack row>
      <IconChip size={48} icon={icons[0]} color="success" />
      {icons.map((ic, i) => (
        <div key={i}>
          <IconChip
            size={20 * (1 + i / 2)}
            icon={ic}
            color={themeColors[i % themeColors.length] as any}
          />
        </div>
      ))}
    </DemoStack>
  ),
};
