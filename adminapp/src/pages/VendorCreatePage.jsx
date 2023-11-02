import api from "../api";
import FormLayout from "../components/FormLayout";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { TextField } from "@mui/material";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";

export default function VendorCreatePage() {
  const navigate = useNavigate();
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const [name, setName] = React.useState("");
  const { isBusy, busy, notBusy } = useBusy();
  const { register, handleSubmit } = useForm();

  const submit = () => {
    busy();
    api
      .createVendor({ name })
      .then(api.followRedirect(navigate))
      .tapCatch(notBusy)
      .catch(enqueueErrorSnackbar);
  };
  return (
    <FormLayout
      title="Create a Vendor"
      subtitle="Vendor represents a vendor of goods and services, like 'Alan's Farm'. It is tied
        to a product. Suma does a wholesale purchase from a vendor. It then lists those
        products, and takes responsibility for inventory and fulfillment."
      onSubmit={handleSubmit(submit)}
      isBusy={isBusy}
    >
      <TextField
        {...register("name")}
        label="Name"
        value={name}
        fullWidth
        onChange={(e) => setName(e.target.value)}
      />
    </FormLayout>
  );
}
