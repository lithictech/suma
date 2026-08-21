import useToggle from "../state/useToggle";
import Button from "../ui/Button";
import ButtonGroup from "../ui/ButtonGroup";
import Card from "../ui/Card";
import CardBody from "../ui/CardBody";
import { Dialog } from "../ui/Dialog";
import DialogHeader from "../ui/DialogHeader";
import Stack from "../ui/Stack";
import type { Meta, StoryObj } from "@storybook/preact-vite";
import React from "react";

function DialogDemo() {
  const dialogToggle = useToggle();
  const dialogFocusRef = React.useRef(null);
  return (
    <>
      <Dialog
        open={dialogToggle.isOn}
        onClose={dialogToggle.turnOff}
        labelledBy="delete-confirm"
        initialFocusRef={dialogFocusRef}
      >
        <Card>
          <CardBody>
            <Stack direction="vertical" gap={3}>
              <DialogHeader id="delete-confirm">
                Are you sure you want to delete this item?
              </DialogHeader>
              <p>This cannot be undone.</p>
              <ButtonGroup>
                <Button
                  variant="text"
                  ref={dialogFocusRef}
                  className="btn btn-secondary"
                  onClick={dialogToggle.turnOff}
                >
                  Cancel
                </Button>
                <Button variant="primary" onClick={dialogToggle.turnOff}>
                  Delete
                </Button>
              </ButtonGroup>
            </Stack>
          </CardBody>
        </Card>
      </Dialog>
      <Button onClick={dialogToggle.turnOn}>Open Dialog</Button>
    </>
  );
}

const meta = {
  title: "Styleguide/Dialogs",
  component: DialogDemo,
} satisfies Meta<typeof DialogDemo>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};
