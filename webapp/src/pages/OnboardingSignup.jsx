import api from "../api";
import FormButtons from "../components/FormButtons";
import FormControlGroup from "../components/FormControlGroup";
import FormError from "../components/FormError";
import OrganizationInputDropdown from "../components/OrganizationInputDropdown";
import { t } from "../localization";
import keepDigits from "../modules/keepDigits";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { extractErrorCode } from "../state/useError";
import useUser from "../state/useUser";
import React from "react";
import Col from "react-bootstrap/Col";
import Form from "react-bootstrap/Form";
import Row from "react-bootstrap/Row";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";

export default function OnboardingSignup() {
  const navigate = useNavigate();
  const { setUser } = useUser();
  const {
    register,
    handleSubmit,
    clearErrors,
    setValue,
    formState: { errors },
  } = useForm({
    mode: "all",
  });

  const [error, setError] = React.useState("");
  const [name, setName] = React.useState("");
  const [address, setAddress] = React.useState("");
  const [address2, setAddress2] = React.useState("");
  const [city, setCity] = React.useState("");
  const [state, setState] = React.useState("");
  const [zipCode, setZipCode] = React.useState("");
  const [organizationName, setOrganizationName] = React.useState("");
  const handleFormSubmit = () => {
    api
      .updateMe({
        name: name,
        address: {
          address1: address,
          address2: address2,
          city: city,
          state_or_province: state,
          postal_code: zipCode,
        },
        organizationName,
      })
      .then((r) => {
        setUser(r.data);
        navigate("/onboarding/finish");
      })
      .catch((err) => {
        setError(extractErrorCode(err));
      });
  };

  const runSetter = (name, set, value) => {
    clearErrors(name);
    setValue(name, value);
    set(value);
  };

  const handleInputChange = (e, set) => {
    runSetter(e.target.name, set, e.target.value || "");
  };

  const handleZipChange = (e) => {
    const v = keepDigits(e.target.value).slice(0, 5);
    runSetter(e.target.name, setZipCode, v);
  };

  const { state: supportedGeographies } = useAsyncFetch(api.getSupportedGeographies, {
    default: {},
    pickData: true,
  });
  return (
    <>
      <h2 className="page-header">{t("onboarding:enroll_title")}</h2>
      {t("onboarding:enroll_intro")}
      <Form noValidate onSubmit={handleSubmit(handleFormSubmit)}>
        <FormControlGroup
          className="mb-3"
          name="name"
          label={t("forms:name")}
          required
          register={register}
          errors={errors}
          value={name}
          onChange={(e) => handleInputChange(e, setName)}
        />
        <FormControlGroup
          className="mb-3"
          name="address"
          label={t("forms:address1")}
          type="text"
          required
          register={register}
          errors={errors}
          value={address}
          onChange={(e) => handleInputChange(e, setAddress)}
        />
        <FormControlGroup
          className="mb-3"
          name="address2"
          label={t("forms:address2")}
          type="text"
          register={register}
          errors={errors}
          value={address2}
          onChange={(e) => handleInputChange(e, setAddress2)}
        />
        <FormControlGroup
          className="mb-3"
          name="city"
          label={t("forms:city")}
          type="text"
          required
          register={register}
          errors={errors}
          value={city}
          onChange={(e) => handleInputChange(e, setCity)}
        />
        <Row className="mb-3">
          <FormControlGroup
            as={Col}
            name="state"
            label={t("forms:state")}
            required
            Input={Form.Select}
            inputClass={state ? null : "select-noselection"}
            register={register}
            errors={errors}
            value={state}
            onChange={(e) => handleInputChange(e, setState)}
          >
            <option disabled value="">
              {t("forms:choose_state")}
            </option>
            {supportedGeographies.provinces?.map((state) => (
              <option key={state.value} value={state.value}>
                {state.label}
              </option>
            ))}
          </FormControlGroup>
          <FormControlGroup
            as={Col}
            name="zip"
            label={t("forms:zip")}
            type="text"
            pattern="^[0-9]{5}(?:-[0-9]{4})?$"
            minLength="5"
            maxLength="10"
            required
            register={register}
            errors={errors}
            value={zipCode}
            onChange={handleZipChange}
          />
        </Row>
        <OrganizationInputDropdown
          organizationName={organizationName}
          onOrganizationNameChange={(name) =>
            runSetter("organizationName", setOrganizationName, name)
          }
          register={register}
          errors={errors}
        />
        <FormError error={error} />
        <FormButtons
          variant="outline-primary"
          back
          primaryProps={{ children: t("forms:submit") }}
        />
      </Form>
    </>
  );
}
