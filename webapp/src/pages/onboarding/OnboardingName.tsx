import { t } from "../../localization";
import useNavigate from "../../routing/useNavigate";
import useUser from "../../state/useUser.ts";
import BackButton from "../../ui/BackButton.tsx";
import BreadcrumbBack from "../../ui/BreadcrumbBack.tsx";
import ButtonGroup from "../../ui/ButtonGroup.tsx";
import ContinueButton from "../../ui/ContinueButton.tsx";
import Form from "../../ui/Form.tsx";
import Page from "../../ui/Page.tsx";
import ProgressStepHeader from "../../ui/ProgressStepHeader.tsx";
import TextInput from "../../ui/TextInput.tsx";
import React from "react";
import { useForm } from "react-hook-form";

export default function OnboardingName() {
  const { user, setUser } = useUser();
  const navigate = useNavigate();

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<{ name: string }>({
    mode: "onBlur",
    reValidateMode: "onBlur",
    defaultValues: { name: user.name },
  });

  function handleSubmitForm(data: { name: string }) {
    setUser({ ...user, name: data.name });
    navigate("/onboarding/address");
  }

  return (
    <Page buffer gap={3}>
      <ProgressStepHeader step={2} steps={5} />
      <BreadcrumbBack back />
      <h1>What is your name?</h1>
      <p>We&rsquo;d love to know what to call you!</p>
      <Form noValidate onSubmit={handleSubmit(handleSubmitForm)}>
        <TextInput
          label="Name"
          {...register("name", { required: t("errors.required") })}
          error={errors.name?.message}
          autoFocus
          required
        />

        <ButtonGroup col bottom>
          <ContinueButton />
          <BackButton to="/onboarding/theme" />
        </ButtonGroup>
      </Form>
    </Page>
  );
}
