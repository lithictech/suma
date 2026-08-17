import api from "../api";
import { t } from "../localization";
import useAsyncFetch from "../state/useAsyncFetch";
import Select, { SelectOption } from "../ui/Select.tsx";
import React from "react";

interface OrganizationInputDropdownProps {
  organizationName: string;
  onOrganizationNameChange: (name: string) => void;
  error?: React.ReactNode;
}

export default function OrganizationInputDropdown({
  organizationName,
  onOrganizationNameChange,
  error,
}: OrganizationInputDropdownProps) {
  const { state: supportedOrganizations } = useAsyncFetch<{ items?: { name: string }[] }>(
    api.getSupportedOrganizations,
    {
      default: {},
      pickData: true,
    }
  );
  return (
    <Select
      name="organizationName"
      label=""
      required
      error={error}
      value={organizationName}
      onChange={(e: React.ChangeEvent<HTMLSelectElement>) =>
        onOrganizationNameChange(e.target.value)
      }
      help={t("forms.organization_helper_text")}
      placeholder={t("forms.choose_organization")}
      options={[
        ...supportedOrganizations.items.map(({ name }) => toSelectOpt(name)),
        toSelectOpt(t("forms.option_unaffiliated")),
        toSelectOpt(t("forms.option_not_listed")),
      ]}
    />
  );
}

function toSelectOpt(s: string): SelectOption {
  return { label: s, value: s };
}
