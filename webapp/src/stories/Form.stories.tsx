import ScreenLoaderProvider from "../state/ScreenLoaderProvider.tsx";
import { useError } from "../state/useError.tsx";
import useScreenLoader from "../state/useScreenLoader.ts";
import Button from "../ui/Button";
import ButtonGroup from "../ui/ButtonGroup";
import Checkbox from "../ui/Checkbox";
import Form from "../ui/Form.tsx";
import FormError from "../ui/FormError.tsx";
import Page from "../ui/Page.tsx";
import PhoneInput from "../ui/PhoneInput.tsx";
import TextInput from "../ui/TextInput";
import type { Meta, StoryObj } from "@storybook/preact-vite";
import { useController, useForm } from "react-hook-form";

function FormDemo() {
  return (
    <ScreenLoaderProvider>
      <FormFields />
    </ScreenLoaderProvider>
  );
}

function FormFields() {
  const [error, setError] = useError();
  const screenLoader = useScreenLoader();

  const {
    register,
    handleSubmit,
    clearErrors,
    control,
    formState: { errors },
  } = useForm<{ name: string; phone: string; agree: boolean }>({
    mode: "onBlur",
    reValidateMode: "onBlur",
  });

  const {
    field: { value: agree, onChange: onAgreeChange, ref: agreeRef },
  } = useController({
    name: "agree",
    control,
    rules: { required: "You must agree to continue" },
    defaultValue: false,
  });

  const handleSubmitForm = () => {
    screenLoader.turnOn();
    setError();
    Promise.delay(300)
      .then(() => {
        if (Math.random() < 0.5) {
          setError(<span>This is a random form error.</span>);
        }
      })
      .finally(screenLoader.turnOff);
  };

  return (
    <Page style={{ minHeight: "70dvh" }}>
      <Form noValidate onSubmit={handleSubmit(handleSubmitForm)}>
        <TextInput
          label="Name"
          {...register("name", { required: "Name is required" })}
          error={errors.name?.message}
          autoFocus
          required
        />
        <PhoneInput
          label="Phone number"
          name="phone"
          control={control}
          clearErrors={clearErrors}
          required
        />
        <Checkbox
          ref={agreeRef}
          label="I agree to the terms"
          checked={!!agree}
          onChange={onAgreeChange}
          error={errors.agree?.message}
          required
        />
        <FormError error={error} />
        <ButtonGroup col bottom>
          <Button type="submit">Continue</Button>
          <Button variant="outline">Back</Button>
        </ButtonGroup>
      </Form>
    </Page>
  );
}

const meta = {
  title: "Styleguide/Form",
  component: FormDemo,
} satisfies Meta<typeof FormDemo>;

export default meta;
type Story = StoryObj<typeof meta>;

export const Default: Story = {};
