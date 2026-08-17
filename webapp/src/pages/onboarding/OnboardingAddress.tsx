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
    progressive: true,
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
          label={t("forms.address1")}
          {...register("address1", buildValidators({ required: true }))}
          autoComplete="address-line1"
          error={errors.address1?.message}
          autoFocus
          required
        />
        <TextInput
          label={t("forms.address2")}
          {...register("address2")}
          autoComplete="address-line2"
          error={errors.address2?.message}
          help="Optional"
        />
        <TextInput
          label={t("forms.city")}
          {...register("city", buildValidators({ required: true }))}
          error={errors.city?.message}
          required
          autoComplete="address-level2"
        />
        <Stack row gap={2}>
          <Select
            label={t("forms.state")}
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
              buildValidators({
                required: true,
                pattern: "^[0-9]{5}(?:-[0-9]{4})?$",
                minLength: 5,
                maxLength: 10,
              })
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
