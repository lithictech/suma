import api from "../api";
import ResourceCreate from "../components/ResourceCreate";
import { stub } from "../modules/formHelpers";
import VendorForm from "./VendorForm";
import React from "react";

export default function VendorCreatePage() {
  const empty = { image: null, imageCaption: stub.translation, name: "" };
  return <ResourceCreate empty={empty} apiCreate={api.createVendor} Form={VendorForm} />;
}
