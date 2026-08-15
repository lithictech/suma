import api from "../api";
import FormButtons from "../components/FormButtons";
import FormControlGroup from "../components/FormControlGroup";
import FormError from "../components/FormError";
import OrganizationInputDropdown from "../components/OrganizationInputDropdown";
import PageHeading from "../components/PageHeading";
import { t } from "../localization";
import keepDigits from "../modules/keepDigits";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { extractErrorCode } from "../state/useError";
import useUser from "../state/useUser";
import Col from "../ui/Col";
import Form from "../ui/Form";
import FormSelect from "../ui/FormSelect";
import Row from "../ui/Row";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";

interface SupportedGeography {
  label: string;
  value: string;
}

interface SupportedGeographies {
  countries?: SupportedGeography[];
  provinces?: SupportedGeography[];
}

export default function OnboardingSignup() {
  const navigate = useNavigate();
  const { setUser, registrationSession } = useUser();
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
  const [organizationName, setOrganizationName] = React.useState(
    registrationSession?.organizationName || ""
  );
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
      .then((r: any) => {
        setUser(r.data);
        navigate("/onboarding/finish");
      })
      .catch((err: any) => {
        setError(extractErrorCode(err));
      });
  };

  const runSetter = (name: string, set: (value: string) => void, value: string) => {
    clearErrors(name);
    setValue(name, value);
    set(value);
  };

  const handleInputChange = (
    e: React.ChangeEvent<HTMLInputElement>,
    set: (value: string) => void
  ) => {
    runSetter(e.target.name, set, e.target.value || "");
  };

  const handleZipChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const v = keepDigits(e.target.value).slice(0, 5);
    runSetter(e.target.name, setZipCode, v);
  };

  const { state: supportedGeographies } = useAsyncFetch<SupportedGeographies>(
    api.getSupportedGeographies,
    {
      default: {},
      pickData: true,
    }
  );
  return (
    <>
      <PageHeading>{t("onboarding.enroll_title")}</PageHeading>
      {t("onboarding.enroll_intro")}
      <Form noValidate onSubmit={handleSubmit(handleFormSubmit)}>
        <FormControlGroup
          className="mb-3"
          name="name"
          autoComplete="name"
          label={t("forms.name")}
          required
          register={register}
          errors={errors}
          value={name}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            handleInputChange(e, setName)
          }
        />
        <FormControlGroup
          className="mb-3"
          name="address"
          autoComplete="address-line1"
          label={t("forms.address1")}
          type="text"
          required
          register={register}
          errors={errors}
          value={address}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            handleInputChange(e, setAddress)
          }
        />
        <FormControlGroup
          className="mb-3"
          name="address2"
          autoComplete="address-line2"
          label={t("forms.address2")}
          type="text"
          register={register}
          errors={errors}
          value={address2}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            handleInputChange(e, setAddress2)
          }
        />
        <FormControlGroup
          className="mb-3"
          name="city"
          autoComplete="address-level2"
          label={t("forms.city")}
          type="text"
          required
          register={register}
          errors={errors}
          value={city}
          onChange={(e: React.ChangeEvent<HTMLInputElement>) =>
            handleInputChange(e, setCity)
          }
        />
        <Row className="mb-3">
          <FormControlGroup
            as={Col}
            name="state"
            label={t("forms.state")}
            required
            Input={FormSelect}
            inputClass={state ? null : "select-noselection"}
            register={register}
            errors={errors}
            value={state}
            onChange={(e: React.ChangeEvent<HTMLSelectElement>) =>
              handleInputChange(e as any, setState)
            }
          >
            <option disabled value="">
              {t("forms.choose_state")}
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
            autoComplete="postal-code"
            inputMode="numeric"
            label={t("forms.zip")}
            type="text"
            pattern="^[0-9]{5}(?:-[0-9]{4})?$"
            minLength={5}
            maxLength={10}
            required
            register={register}
            errors={errors}
            value={zipCode}
            onChange={handleZipChange}
          />
        </Row>
        {registrationSession?.organizationName ? (
          <div>
            {t("onboarding.partner_registration")}:{" "}
            {registrationSession?.organizationName}
          </div>
        ) : (
          <OrganizationInputDropdown
            organizationName={organizationName}
            onOrganizationNameChange={(name: string) =>
              runSetter("organizationName", setOrganizationName, name)
            }
            register={register}
            errors={errors}
          />
        )}
        <FormError error={error} />
        <FormButtons
          variant="outline"
          back
          primaryProps={{ children: t("forms.submit") }}
        />
      </Form>
    </>
  );
}
