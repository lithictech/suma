import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import { dayjs } from "../modules/dayConfig";
import { stub } from "../modules/formHelpers";
import ProgramForm from "./ProgramForm";
import React from "react";

export default function ProgramCreatePage() {
  const empty = {
    image: null,
    imageCaption: stub.translation,
    name: stub.translation,
    description: stub.translation,
    appLink: "",
    appLinkText: stub.translation,
    periodBegin: dayjs().format(),
    periodEnd: dayjs().add(1, "day").format(),
    commerceOfferings: stub.collection,
    ordinal: 0,
  };
  return (
    <ResourceCreate empty={empty} apiCreate={api.createProgram} Form={ProgramForm} />
  );
}
