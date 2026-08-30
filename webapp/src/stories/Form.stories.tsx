import ScreenLoaderProvider from "../state/ScreenLoaderProvider.tsx";
import { useError } from "../state/useError.tsx";
import useMountEffect from "../state/useMountEffect.ts";
import useScreenLoader from "../state/useScreenLoader.ts";
import Button from "../ui/Button";
import ButtonGroup from "../ui/ButtonGroup";
import Checkbox from "../ui/Checkbox";
import Form from "../ui/Form.tsx";
import FormError from "../ui/FormError.tsx";
import FormFeedback from "../ui/FormFeedback.tsx";
import Page from "../ui/Page.tsx";
import PhoneInput from "../ui/PhoneInput.tsx";
import TextInput from "../ui/TextInput";
import type { Meta, StoryObj } from "@storybook/preact-vite";
import { useController, useForm } from "react-hook-form";

const meta = {
  title: "Styleguide/Form",
  decorators: [
    (Story) => (
      <ScreenLoaderProvider>
        {/* @ts-expect-error Story's Preact/React JSX typings don't line up here; safe to render. */}
        <Story />
      </ScreenLoaderProvider>
    ),
  ],
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const Demo: Story = {
  render: () => {
    // eslint-disable-next-line react-hooks/rules-of-hooks
    const [error, setError] = useError();
    // eslint-disable-next-line react-hooks/rules-of-hooks
    const screenLoader = useScreenLoader();

    const {
      register,
      handleSubmit,
      clearErrors,
      control,
      formState: { errors },
      // eslint-disable-next-line react-hooks/rules-of-hooks
    } = useForm<{ name: string; phone: string; agree: boolean }>({
      mode: "onBlur",
      reValidateMode: "onBlur",
    });

    const {
      field: { value: agree, onChange: onAgreeChange, ref: agreeRef },
      // eslint-disable-next-line react-hooks/rules-of-hooks
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
      <Page>
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
            checked={agree}
            onChange={onAgreeChange}
            error={errors.agree?.message}
            required
          />
          <FormError error={error} />
          <FormSubmit label="Continue" error={error} />
          <ButtonGroup col bottom>
            <Button type="submit">Continue</Button>
            <Button variant="outline">Back</Button>
          </ButtonGroup>
        </Form>
      </Page>
    );
  },
};

export const WithError: Story = {
  render: () => (
    <Page>
      <Form noValidate>
        <TextInput label="Name" />
        <TextInput label="Address" />
        <FormFeedback error="forbidden." />
        <ButtonGroup col bottom>
          <Button type="submit">Continue</Button>
          <Button variant="outline">Back</Button>
        </ButtonGroup>
      </Form>
    </Page>
  ),
};

export const WithSuccess: Story = {
  render: () => (
    <Page>
      <Form noValidate>
        <TextInput label="Name" />
        <TextInput label="Address" />
        <FormFeedback success="It worked!" />
        <ButtonGroup col bottom>
          <Button type="submit">Continue</Button>
          <Button variant="outline">Back</Button>
        </ButtonGroup>
      </Form>
    </Page>
  ),
};

export const Loading: Story = {
  render: () => {
    // eslint-disable-next-line react-hooks/rules-of-hooks
    const screenLoader = useScreenLoader();
    // eslint-disable-next-line react-hooks/rules-of-hooks
    useMountEffect(() => screenLoader.turnOn());
    return (
      <Page>
        <Form noValidate>
          <TextInput label="Name" />
          <TextInput label="Address" />
          <ButtonGroup col bottom>
            <Button type="submit">Continue</Button>
            <Button variant="outline">Back</Button>
          </ButtonGroup>
        </Form>
      </Page>
    );
  },
};
