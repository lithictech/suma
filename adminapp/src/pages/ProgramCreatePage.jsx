import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import { dayjs } from "../modules/dayConfig";
import formHelpers from "../modules/formHelpers";
import ProgramForm from "./ProgramForm";
import React from "react";

export default function ProgramCreatePage() {
  const empty = {
    image: null,
    imageCaption: formHelpers.initialTranslation,
    name: formHelpers.initialTranslation,
    description: formHelpers.initialTranslation,
    appLink: "",
    appLinkText: formHelpers.initialTranslation,
    periodBegin: dayjs().format(),
    periodEnd: dayjs().add(1, "day").format(),
    vendorServices: [],
    commerceOfferings: [],
    ordinal: 0,
  };
  return (
    <ResourceCreate empty={empty} apiCreate={api.createProgram} Form={ProgramForm} />
  );
}
