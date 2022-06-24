import api from "../api";
import FormButtons from "../components/FormButtons";
import FormControlGroup from "../components/FormControlGroup";
import FormError from "../components/FormError";
import { t } from "../localization";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import { extractErrorCode } from "../state/useError";
import { useUser } from "../state/useUser";
import React from "react";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
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
    runSetter(e.target.name, set, e.target.value);
  };

  const handleZipChange = (e) => {
    const v = e.target.value.replace(/\D/, "").slice(0, 5);
    runSetter(e.target.name, setZipCode, v);
  };

  const { state: supportedGeographies } = useAsyncFetch(api.getSupportedGeographies, {
    default: {},
    pickData: true,
  });

  return (
    <Container>
      <Row>
        <Col>
          <h2>Enroll in Suma</h2>
          <p>
            Welcome to Suma! To get started, we will need to verify your identity. This
            makes sure you are eligible for the right programs, such as with our
            affordable housing partners.
          </p>
          <p>
            <strong>
              We will never share this information other than to verify your identity.
            </strong>
          </p>
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
                register={register}
                errors={errors}
                value={state}
                onChange={(e) => handleInputChange(e, setState)}
              >
                <option disabled value="">
                  Choose state...
                </option>
                {!!supportedGeographies.provinces &&
                  supportedGeographies.provinces.map((state) => (
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
            <FormError error={error} />
            <FormButtons
              variant="success"
              back
              primaryProps={{ children: t("forms:submit") }}
            />
          </Form>
        </Col>
      </Row>
    </Container>
  );
}
