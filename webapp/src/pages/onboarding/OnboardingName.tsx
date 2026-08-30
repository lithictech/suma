import { r } from "../../localization";
import BackButton from "../../ui/BackButton.tsx";
import BreadcrumbBack from "../../ui/BreadcrumbBack.tsx";
import ButtonGroup from "../../ui/ButtonGroup.tsx";
import ContinueButton from "../../ui/ContinueButton.tsx";
import Form from "../../ui/Form.tsx";
import Page from "../../ui/Page.tsx";
import ProgressStepHeader from "../../ui/ProgressStepHeader.tsx";
import TextInput from "../../ui/TextInput.tsx";
import { OnboardingProps } from "./onboardingTypes.ts";
import { useForm } from "react-hook-form";

export default function OnboardingName({
  stepForward,
  stepBackward,
  onboardingState,
  setOnboardingField,
}: OnboardingProps) {
  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<{ name: string }>({
    mode: "onBlur",
    reValidateMode: "onBlur",
    defaultValues: { name: onboardingState.name },
  });

  function handleSubmitForm(data: { name: string }) {
    setOnboardingField("name", data.name);
    stepForward();
  }

  return (
    <Page>
      <ProgressStepHeader
        step={onboardingState.step}
        steps={onboardingState.totalSteps}
      />
      <BreadcrumbBack back />
      <h1>What is your name?</h1>
      <p>We&rsquo;d love to know what to call you!</p>
      <Form noValidate onSubmit={handleSubmit(handleSubmitForm)}>
        <TextInput
          label="Name"
          {...register("name", { required: r("errors.required") })}
          error={errors.name?.message}
          autoFocus
          required
        />
        <ButtonGroup col bottom>
          <ContinueButton />
          <BackButton onClick={stepBackward} />
        </ButtonGroup>
      </Form>
    </Page>
  );
}
