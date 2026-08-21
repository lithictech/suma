import CardText from "../ui/CardText";
import Checkbox from "../ui/Checkbox";
import CheckboxCard from "../ui/CheckboxCard";
import RadioCard from "../ui/RadioCard.tsx";
import Select from "../ui/Select";
import Stack from "../ui/Stack";
import Switch from "../ui/Switch";
import TextInput from "../ui/TextInput";
import noop from "lodash/noop";
import type { Meta, StoryObj } from "@storybook/preact-vite";

const LOREM_IPSUM =
  "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras sed ligula blandit, " +
  "dictum massa quis, lobortis metus. Nunc ac justo nec ante tincidunt euismod ut vel " +
  "libero. Sed gravida porta malesuada. Sed iaculis pretium urna vel elementum.";

const meta = {
  title: "Styleguide/Inputs",
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const TextInputs: Story = {
  render: () => (
    <Stack gap={2} wrap>
      <TextInput
        label="Zip"
        value=""
        help="Five digits."
        placeholder="12345 (placeholder)"
      />
      <TextInput
        label="Zip"
        value="97211"
        help="Five digits."
        inputClass="is-focus-visible"
      />
      <TextInput label="Zip" value="9721" help="Five digits." disabled />
      <TextInput label="Zip" value="9721" help="Five digits." error="Zip code is 5 digits." />
    </Stack>
  ),
};

export const Checkboxes: Story = {
  render: () => (
    <Stack direction="vertical" gap={2}>
      <Stack gap={2}>
        <Checkbox label="Checkbox 1" checked={false} />
        <Checkbox label="Checkbox 2" checked />
        <Checkbox checked={false} />
      </Stack>
      <Checkbox label="Invalid" checked={false} error="Must agree to continue" />
      <Stack gap={2}>
        <Switch label="Switch 1" checked={false} />
        <Switch label="Switch 2" checked />
        <Switch checked={false} />
      </Stack>
      <Switch label="Invalid switch" checked={false} error="Must turn on to continue" />
      <RadioCard
        name="radio"
        options={[
          { value: "a", label: "Option A" },
          {
            value: "b",
            label: (
              <div>
                <p>The radio card contents</p>
                <p className="text-muted font-weight-bold">can be styled normally.</p>
              </div>
            ),
          },
          { value: "c", label: "Option C" },
        ]}
        value=""
        onValueChange={noop}
      />
      <CheckboxCard
        title="When an order is ready"
        text="A text the morning it lands"
        checked={false}
      />
      <CheckboxCard
        title="When an order is ready"
        text="A text the morning it lands"
        checked
      />
      <CheckboxCard checked={false} error="Must check to continue" alignCheckbox="start">
        <CardText style={{ maxHeight: 100, overflowY: "scroll" }}>{LOREM_IPSUM}</CardText>
      </CheckboxCard>
      <CheckboxCard checked={false} alignCheckbox="start">
        <CardText style={{ maxHeight: 100, overflowY: "scroll" }}>{LOREM_IPSUM}</CardText>
      </CheckboxCard>
    </Stack>
  ),
};

export const SelectInput: Story = {
  render: () => (
    <Stack direction="vertical" gap={2}>
      <Select
        label="Select"
        value="optb"
        options={[
          { label: "Option A", value: "opta" },
          { label: "Option B", value: "optb" },
          { label: "Option C", value: "optc" },
          { label: "Option D", value: "optd" },
        ]}
      />
      <Select
        label="Select"
        value=""
        options={[{ label: "Option A", value: "opta" }]}
        error="Must select an option."
      />
    </Stack>
  ),
};
