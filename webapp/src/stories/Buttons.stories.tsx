import type { RoutePath } from "../routing/RoutePath.ts";
import Button, { ButtonProps } from "../ui/Button";
import ButtonGroup from "../ui/ButtonGroup";
import Icon from "../ui/Icon.tsx";
import IconButton from "../ui/IconButton.tsx";
import Stack from "../ui/Stack";
import { DemoStack } from "./helpers.tsx";
import { TrashIcon } from "@heroicons/react/24/outline";
import ChevronRightIcon from "@heroicons/react/24/outline/ChevronRightIcon";
import type { Meta, StoryObj } from "@storybook/preact-vite";
import React from "react";

const BUTTON_PROPS: ButtonProps[] = [
  { children: "Continue", variant: "filled" },
  { children: "Skip for now", variant: "text" },
  { children: "Add", variant: "outline" },
  { children: "Danger", variant: "filled", color: "danger" },
  { children: "Danger", variant: "text", color: "danger" },
  { children: "Danger", variant: "outline", color: "danger" },
  { children: "Success", variant: "filled", color: "success" },
  { children: "Success", variant: "text", color: "success" },
  { children: "Success", variant: "outline", color: "success" },
  { children: "Large Btn", size: "lg" },
  { children: "Small Btn", variant: "outline", size: "sm" },
  { children: "Inline", variant: "text", inline: true },
] as const;

const BUTTON_STATES = ["", "is-hover", "is-focus-visible", "is-disabled"];

const meta = {
  title: "Styleguide/Buttons",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const Variants: Story = {
  render: () => (
    <DemoStack>
      {BUTTON_PROPS.map(({ ...props }, i) => (
        <React.Fragment key={i}>
          <Stack gap={2}>
            {BUTTON_STATES.map((st) => (
              <Button
                key={st}
                className={st}
                disabled={st === "is-disabled"}
                {...props}
              />
            ))}
          </Stack>
        </React.Fragment>
      ))}
    </DemoStack>
  ),
};

export const LinkButtons: Story = {
  render: () => (
    <DemoStack>
      {BUTTON_PROPS.map((props) => (
        <Stack key={JSON.stringify(props)} gap={2} wrap>
          {BUTTON_STATES.map((st) => (
            <Button
              key={st}
              className={st}
              disabled={st === "is-disabled"}
              {...props}
              to={"#" as RoutePath}
            />
          ))}
        </Stack>
      ))}
    </DemoStack>
  ),
};

export const Groups: Story = {
  render: () => (
    <DemoStack>
      <h2>Horizontal</h2>
      <ButtonGroup>
        <Button>Primary Action</Button>
        <Button preset="secondary">Secondary Action</Button>
      </ButtonGroup>
      <h2>Vertical</h2>
      <ButtonGroup vertical>
        <Button>Primary Action</Button>
        <Button preset="secondary">Secondary Action</Button>
      </ButtonGroup>
      <h2>Inline</h2>
      <Stack col>
        <p>Some text</p>
        <p>Some text</p>
        <Stack row center className="justify-content-between" style={{ maxWidth: 250 }}>
          <p>Some text</p>
          <Button variant="text" inline>
            <Icon icon={ChevronRightIcon} />
          </Button>
        </Stack>
        <p>Some text</p>
        <p>Some text</p>
      </Stack>
    </DemoStack>
  ),
};

export const Icons: Story = {
  render: () => (
    <DemoStack>
      <IconButton icon={TrashIcon} />
      <IconButton icon={TrashIcon} color="success" />
      <IconButton icon={TrashIcon} color="danger" />
      <IconButton icon={TrashIcon} variant="outline" />
      <IconButton icon={TrashIcon} variant="text" />
      <IconButton icon={TrashIcon} size="sm" />
      <IconButton icon={TrashIcon} size="lg" />
    </DemoStack>
  ),
};
