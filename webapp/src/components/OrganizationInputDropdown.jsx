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
  const inputRef = React.useRef();
  const supportedOrgNames = supportedOrganizations.items?.map(({ name }) => name) || [];
  const unaffiliated = t("forms:option_unaffiliated");
  const isPreselectedOrg =
    organizationName === unaffiliated || supportedOrgNames.includes(organizationName);
  function handleSelect(v) {
    if (v === t("forms:option_not_listed")) {
      onOrganizationNameChange("");
      inputRef.current.disabled = false;
      inputRef.current.focus();
    } else {
      onOrganizationNameChange(v);
    }
  }
  return (
    <FormControlGroup
      inputRef={inputRef}
      name="organizationName"
      label={t("forms:organization_label")}
      required
      disabled={isPreselectedOrg}
      register={register}
      errors={errors}
      value={organizationName}
      onChange={(e) => onOrganizationNameChange(e.target.value)}
      append={
        <Dropdown as={ButtonGroup} onSelect={handleSelect}>
          <Dropdown.Toggle className="fs-6 rounded-0">
            {t("forms:choose")}
          </Dropdown.Toggle>
          <Dropdown.Menu align="end">
            {supportedOrgNames.map((name) => (
              <Dropdown.Item
                key={name}
                eventKey={name}
                active={name === organizationName}
              >
                {name}
              </Dropdown.Item>
            ))}
            <Dropdown.Divider />
            <Dropdown.Item
              key={t("forms:option_not_listed")}
              eventKey={t("forms:option_not_listed")}
            >
              {t("forms:option_not_listed")}
            </Dropdown.Item>
            <Dropdown.Item
              key={unaffiliated}
              eventKey={unaffiliated}
              active={unaffiliated === organizationName}
            >
              {unaffiliated}
            </Dropdown.Item>
          </Dropdown.Menu>
        </Dropdown>
      }
      text={t("forms:organization_helper_text")}
    />
  );
}
