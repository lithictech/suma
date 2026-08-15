import api from "../api";
import FormButtons from "../components/FormButtons";
import FormControlGroup from "../components/FormControlGroup";
import FormError from "../components/FormError";
import PhoneInput from "../components/PhoneInput";
import { t } from "../localization";
import { extractLocalizedError, useError } from "../state/useError";
import useToggle from "../state/useToggle";
import Button from "../ui/Button";
import Form from "../ui/Form";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";

export default function RegainAccountAccess({ success }: { success?: boolean }) {
  const navigate = useNavigate();
  const submitting = useToggle(false);
  const [error, setError] = useError();
  const [state, setState] = React.useState({
    name: "",
    currentPhone: "",
    previousPhone: "",
  });

  const {
    register,
    handleSubmit,
    clearErrors,
    setValue,
    formState: { errors },
  } = useForm({
    mode: "all",
  });

  function handlePhoneChange(e: React.ChangeEvent<HTMLInputElement>, formatted: string) {
    clearErrors();
    setValue(e.target.name, formatted);
    setState({ ...state, [e.target.name]: formatted });
  }

  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
    clearErrors();
    setValue(e.target.name, e.target.value);
    setState({ ...state, [e.target.name]: e.target.value });
  }

  function handleSubmitForm() {
    submitting.turnOn();
    setError(null);
    api
      .supportRegainAccountAccess(state)
      .then(() => navigate("/regain-account-access/success", { replace: true }))
      .catch((err: any) => {
        setError(extractLocalizedError(err));
        submitting.turnOff();
      });
  }
  if (success) {
    return (
      <div className="d-flex flex-column">
        <h2>{t("common.thank_you")}</h2>
        <p>{t("auth.access_account_confirmed")}</p>
        <Button
          variant="outline"
          to="/"
          className="w-100 align-self-center"
          style={{ maxWidth: 330 }}
        >
          {t("common.return_home")}
        </Button>
      </div>
    );
  }
  return (
    <>
      <h2>{t("auth.access_account_title")}</h2>
      <p>{t("auth.access_account_subtitle")}</p>
      <Form noValidate onSubmit={handleSubmit(handleSubmitForm)}>
        <PhoneInput
          className="mb-3"
          name="previousPhone"
          label={t("auth.access_account_previous_phone")}
          register={register}
          errors={errors}
          value={state.previousPhone}
          autoFocus
          required
          disabled={submitting.isOn}
          onPhoneChange={handlePhoneChange}
        />
        <PhoneInput
          className="mb-3"
          name="currentPhone"
          label={t("auth.access_account_current_phone")}
          register={register}
          errors={errors}
          value={state.currentPhone}
          autoFocus
          required
          disabled={submitting.isOn}
          onPhoneChange={handlePhoneChange}
        />
        <FormControlGroup
          className="mb-3"
          name="name"
          autoComplete="name"
          label={t("forms.name")}
          required
          register={register}
          errors={errors}
          value={state.name}
          disabled={submitting.isOn}
          onChange={handleChange}
        />
        <FormError error={error} />
        <FormButtons
          back
          primaryProps={{
            children: t("forms.submit"),
            disabled: submitting.isOn,
          }}
        />
      </Form>
    </>
  );
}
