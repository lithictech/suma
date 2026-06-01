import { simplifyCollections } from "../modules/apicollection";
import ResourceForm from "./ResourceForm";
import React from "react";

export default function ResourceCreate({ empty, apiCreate, Form }) {
  const handleApplyChange = React.useCallback(
    (changes) => {
      return apiCreate(simplifyCollections({ ...empty, ...changes }));
    },
    [apiCreate, empty]
  );

  return (
    <ResourceForm
      InnerForm={Form}
      baseResource={empty}
      isCreate
      applyChange={handleApplyChange}
    />
  );
}
