import api from "../api";
import { t } from "../localization";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import FormControlGroup from "./FormControlGroup";
import React from "react";
import ButtonGroup from "react-bootstrap/ButtonGroup";
import Dropdown from "react-bootstrap/Dropdown";

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
    <FormControlGroup
      name="organizationName"
      label={t("forms:organization_label")}
      required
      register={register}
      errors={errors}
      value={organizationName}
      onChange={(e) => onOrganizationNameChange(e.target.value)}
      append={
        <Dropdown as={ButtonGroup} onSelect={(v) => onOrganizationNameChange(v)}>
          <Dropdown.Toggle className="fs-6 rounded-0">
            {t("forms:choose")}
          </Dropdown.Toggle>
          <Dropdown.Menu align="end">
            {supportedOrganizations.items?.map((name) => (
              <Dropdown.Item
                key={name}
                eventKey={name}
                active={name === organizationName}
              >
                {name}
              </Dropdown.Item>
            ))}
          </Dropdown.Menu>
        </Dropdown>
      }
      text={t("forms:organization_helper_text")}
    />
  );
}
