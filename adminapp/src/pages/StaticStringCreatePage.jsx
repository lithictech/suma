import api from "../api";
import FormLayout from "../components/FormLayout";
import ResourceCreate from "../components/ResourceCreate";
import ResponsiveStack from "../components/ResponsiveStack";
import { TextField } from "@mui/material";
import React from "react";
import { useSearchParams } from "react-router-dom";

export default function StaticStringCreatePage() {
  const [params] = useSearchParams();
  const empty = {
    namespace: params.get("namespace") || "",
    key: params.get("key") || "",
  };
  return <ResourceCreate empty={empty} apiCreate={api.createStaticString} Form={Form} />;
}

function Form({ resource, setFieldFromInput, register, isBusy, onSubmit }) {
  const [params] = useSearchParams();
  return (
    <FormLayout
      title={"Create Static String"}
      subtitle="Set the namespace and key. Fill in the localization values on the editor page."
      onSubmit={onSubmit}
      isBusy={isBusy}
    >
      <ResponsiveStack spacing={2}>
        <TextField
          {...register("namespace")}
          label="Namespace"
          name="namespace"
          value={resource.namespace}
          fullWidth
          disabled={Boolean(params.get("namespace"))}
          onChange={setFieldFromInput}
        />
        <TextField
          {...register("key")}
          label="Key"
          name="key"
          value={resource.key}
          fullWidth
          disabled={Boolean(params.get("key"))}
          onChange={setFieldFromInput}
        />
      </ResponsiveStack>
    </FormLayout>
  );
}
