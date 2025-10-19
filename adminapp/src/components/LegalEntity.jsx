import DetailGrid from "./DetailGrid";
import isEmpty from "lodash/isEmpty";
import React from "react";

export default function LegalEntity({ legalEntity }) {
  if (isEmpty(legalEntity)) {
    return null;
  }
  const { name, address } = legalEntity;
  const { address1, address2, city, stateOrProvince, postalCode, country } =
    address || {};
  return (
    <div>
      <DetailGrid
        title="Legal Entity"
        properties={[
          { label: "Name", value: name },
          {
            label: "Street Address",
            value: [address1, address2].filter(Boolean).join(" "),
          },
          { label: "City", value: city },
          { label: "State", value: stateOrProvince },
          { label: "Postal Code", value: postalCode },
          { label: "Country", value: country },
        ]}
      />
    </div>
  );
}
