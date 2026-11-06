import api from "../api";
import FormButtons from "../components/FormButtons";
import FormControlGroup, { RequiredFieldsNote } from "../components/FormControlGroup";
import FormError from "../components/FormError";
import PhoneInput from "../components/PhoneInput";
import RLink from "../components/RLink.jsx";
import { t } from "../localization";
import useFormDraft from "../shared/react/useFormDraft";
import useToggle from "../shared/react/useToggle";
import { extractLocalizedError, useError } from "../state/useError";
import React from "react";
import Button from "react-bootstrap/Button";
import Form from "react-bootstrap/Form";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";

export default function RegainAccountAccess({ success }) {
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
    watch,
    formState: { errors },
  } = useForm({
    mode: "all",
  });

  // Keep what was typed if the page is reloaded before submitting (2.2.5).
  const { clearDraft } = useFormDraft({
    watch,
    setValue,
    fields: DRAFT_FIELDS,
    onRestore: (draft) => setState((s) => ({ ...s, ...draft })),
  });

  function handlePhoneChange(e, formatted) {
    clearErrors();
    setValue(e.target.name, formatted);
    setState({ ...state, [e.target.name]: formatted });
  }

  function handleChange(e) {
    clearErrors();
    setValue(e.target.name, e.target.value);
    setState({ ...state, [e.target.name]: e.target.value });
  }

  function handleSubmitForm() {
    submitting.turnOn();
    setError(null);
    api
      .supportRegainAccountAccess(state)
      .then(() => {
        clearDraft();
        navigate("/regain-account-access/success", { replace: true });
      })
      .catch((err) => {
        setError(extractLocalizedError(err));
        submitting.turnOff();
      });
  }
  if (success) {
    return (
      <div className="d-flex flex-column">
        <h1 className="h2">{t("common.thank_you")}</h1>
        <p>{t("auth.access_account_confirmed")}</p>
        <Button
          variant="outline-primary"
          as={RLink}
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
      <h1 className="h2">{t("auth.access_account_title")}</h1>
      <p>{t("auth.access_account_subtitle")}</p>
      <Form noValidate onSubmit={handleSubmit(handleSubmitForm)}>
        <RequiredFieldsNote />
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

const DRAFT_FIELDS = ["previousPhone", "currentPhone", "name"];
