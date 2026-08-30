import { appError } from "../modules/errors.ts";
import ScreenLoaderProvider from "../state/ScreenLoaderProvider.tsx";
import useError from "../state/useError.tsx";
import useMountEffect from "../state/useMountEffect.ts";
import useScreenLoader from "../state/useScreenLoader.ts";
import Button from "../ui/Button";
import ButtonGroup from "../ui/ButtonGroup";
import Checkbox from "../ui/Checkbox";
import Form from "../ui/Form.tsx";
import FormError from "../ui/FormError.tsx";
import FormSubmit from "../ui/FormSubmit.tsx";
import Page from "../ui/Page.tsx";
import PhoneInput from "../ui/PhoneInput.tsx";
import TextInput from "../ui/TextInput";
import type { Meta, StoryObj } from "@storybook/preact-vite";
import React from "react";
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
      setError(null);
      Promise.delay(300, Promise.resolve())
        .then(() => {
          if (Math.random() < 0.5) {
            setError(appError("forbidden"));
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
        </Form>
      </Page>
    );
  },
};

export const WithError: Story = {
  render: () => {
    const ae = appError("forbidden");
    const [err, setErr] = useError(ae);
    function submit(e: React.FormEvent) {
      e.preventDefault();
      setErr(null);
      window.setTimeout(() => setErr(ae), 1000);
    }
    return (
      <Page>
        <Form noValidate onSubmit={submit}>
          <TextInput label="Name" />
          <TextInput label="Address" />
          <FormSubmit label="Continue" error={err} />
        </Form>
      </Page>
    );
  },
};

export const WithSuccess: Story = {
  render: () => {
    const m = "It worked!";
    const [msg, setMsg] = React.useState(m);
    function submit(e: React.FormEvent) {
      e.preventDefault();
      setMsg("");
      window.setTimeout(() => setMsg(m), 1000);
    }
    return (
      <Page>
        <Form noValidate onSubmit={submit}>
          <TextInput label="Name" />
          <TextInput label="Address" />
          <FormSubmit label="Submit" success={msg} secondary="Cancel" />
        </Form>
      </Page>
    );
  },
};

export const Loading: Story = {
  render: () => {
    const screenLoader = useScreenLoader();
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
