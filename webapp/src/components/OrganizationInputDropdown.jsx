import api from "../api";
import { t } from "../localization";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import FormControlGroup from "./FormControlGroup";
import FormText from "./FormText";
import React from "react";
import Form from "react-bootstrap/Form";

export default function OrganizationInputDropdown({
  organizationName,
  onOrganizationNameChange,
  register,
  errors,
}) {
  const { state: supportedOrganizations } = useAsyncFetch(api.getSupportedOrganizations, {
    default: {},
    pickData: true,
  });
  return (
    <>
      <FormControlGroup
        name="organizationName"
        Input={Form.Select}
        inputClass={organizationName ? null : "select-noselection"}
        required
        register={register}
        errors={errors}
        value={organizationName}
        onChange={(e) => onOrganizationNameChange(e.target.value)}
      >
        <option disabled value="">
          {t("forms:choose_organization")}
        </option>
        {supportedOrganizations.items?.map(({ name }) => (
          <option key={name} value={name}>
            {name}
          </option>
        ))}
        <option value={t("forms:option_unaffiliated")}>
          {t("forms:option_unaffiliated")}
        </option>
        <option value={t("forms:option_not_listed")}>
          {t("forms:option_not_listed")}
        </option>
      </FormControlGroup>
      <FormText>{t("forms:organization_helper_text")}</FormText>
    </>
  );
}
