import api from "../api";
import { t } from "../localization";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import FormControlGroup from "./FormControlGroup";
import React from "react";
import ButtonGroup from "react-bootstrap/ButtonGroup";
import Dropdown from "react-bootstrap/Dropdown";

export default function OrganizationInputDropdown({
  organization,
  onOrganizationChange,
  register,
  errors,
}) {
  const { state: supportedOrganizations } = useAsyncFetch(api.getSupportedOrganizations, {
    default: {},
    pickData: true,
  });
  return (
    <FormControlGroup
      name="organization"
      label={t("forms:organization_label")}
      required
      register={register}
      errors={errors}
      value={organization.name}
      onChange={(e) => onOrganizationChange({ name: e.target.value })}
      append={
        <Dropdown as={ButtonGroup} onSelect={(v) => onOrganizationChange({ name: v })}>
          <Dropdown.Toggle className="fs-6 rounded-0">
            {t("forms:choose")}
          </Dropdown.Toggle>
          <Dropdown.Menu align="end">
            {supportedOrganizations.items?.map((name) => (
              <>
                <Dropdown.Item
                  key={name}
                  eventKey={name}
                  active={name === organization.name}
                >
                  {name}
                </Dropdown.Item>
              </>
            ))}
            <Dropdown.Item
              key={t("forms:option_unsure")}
              eventKey={t("forms:option_unsure")}
              active={t("forms:option_unsure") === organization.name}
            >
              {t("forms:option_unsure")}
            </Dropdown.Item>
          </Dropdown.Menu>
        </Dropdown>
      }
      text={t("forms:organization_helper_text")}
    />
  );
}
