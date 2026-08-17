import api from "../../api.ts";
import { t } from "../../localization";
import { buildValidators } from "../../modules/formValidators.ts";
import useAsyncFetch from "../../state/useAsyncFetch.ts";
import BackButton from "../../ui/BackButton.tsx";
import BreadcrumbBack from "../../ui/BreadcrumbBack.tsx";
import ButtonGroup from "../../ui/ButtonGroup.tsx";
import ContinueButton from "../../ui/ContinueButton.tsx";
import Form from "../../ui/Form.tsx";
import Page from "../../ui/Page.tsx";
import Select from "../../ui/Select.tsx";
import Stack from "../../ui/Stack.tsx";
import TextInput from "../../ui/TextInput.tsx";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";

export default function OnboardingAddress() {
  const { state: supportedGeographies } = useAsyncFetch<SupportedGeographies>(
    api.getSupportedGeographies,
    {
      default: { countries: [], provinces: [] },
      pickData: true,
    }
  );

  const {
    register,
    handleSubmit,
    formState: { errors },
  } = useForm<{
    address1: string;
    address2: string;
    city: string;
    stateOrProvince: string;
    postalCode: string;
  }>({
    mode: "onBlur",
    reValidateMode: "onBlur",
  });
  const navigate = useNavigate();

  function handleSubmitForm(data: {
    address1: string;
    address2: string;
    city: string;
    stateOrProvince: string;
    postalCode: string;
  }) {
    // setUser({ ...user, name: data.name });
    navigate("/onboarding/eligibility");
  }

  return (
    <Page buffer gap={3}>
      <BreadcrumbBack back />
      <h1>Where do you live?</h1>
      <p>We use this to find programs near you.</p>
      <Form noValidate onSubmit={handleSubmit(handleSubmitForm)}>
        <TextInput
          label="Street address"
          {...register("address1", buildValidators({ required: true }))}
          error={errors.address1?.message}
          autoFocus
          required
        />
        <TextInput
          label="Unit or apartment number"
          {...register("address2")}
          error={errors.address2?.message}
          help="Optional"
        />
        <TextInput
          label="City"
          {...register("city", buildValidators({ required: true }))}
          error={errors.city?.message}
          required
        />
        <Stack row gap={2}>
          <Select
            label="State"
            {...register("stateOrProvince", buildValidators({ required: true }))}
            error={errors.stateOrProvince?.message}
            required
            placeholder={t("forms.choose_state")}
            options={supportedGeographies.provinces.map(({ label, value }) => ({
              label,
              value,
            }))}
          />
          <TextInput
            label={t("forms.zip")}
            {...register(
              "postalCode",
              buildValidators({ required: true, pattern: "^[0-9]{5}(?:-[0-9]{4})?$" })
            )}
            error={errors.postalCode?.message}
            required
            autoComplete="postal-code"
            inputMode="numeric"
          />
        </Stack>

        <ButtonGroup col bottom>
          <ContinueButton />
          <BackButton />
        </ButtonGroup>
      </Form>
    </Page>
  );
}
