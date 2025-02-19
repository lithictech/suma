import api from "../api";
import ResourceEdit from "../components/ResourceEdit";
import MobilityTripForm from "./MobilityTripForm.jsx";
import React from "react";

export default function MobilityTripEditPage() {
  return (
    <ResourceEdit
      apiGet={api.getMobilityTrip}
      apiUpdate={api.updateMobilityTrip}
      Form={MobilityTripForm}
    />
  );
}
