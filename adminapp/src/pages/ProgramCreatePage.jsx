import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import { dayjs } from "../modules/dayConfig";
import formHelpers from "../modules/formHelpers";
import VendibleGroupForm from "./ProgramForm";
import React from "react";

export default function ProgramCreatePage() {
  const empty = {
    image: null,
    name: formHelpers.initialTranslation,
    description: formHelpers.initialTranslation,
    periodBegin: dayjs().format(),
    periodEnd: dayjs().add(1, "day").format(),
    vendorServices: [],
    commerceOfferings: [],
  };
  return (
    <ResourceCreate
      empty={empty}
      apiCreate={api.createProgram}
      Form={VendibleGroupForm}
    />
  );
}
