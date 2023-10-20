import api from "../api";
import FormButtons from "../components/FormButtons";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { Stack, TextField, Typography } from "@mui/material";
import Box from "@mui/material/Box";
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
    <div style={{ maxWidth: 650 }}>
      <Typography variant="h4" gutterBottom>
        Create a Vendor
      </Typography>
      <Typography variant="body1" gutterBottom>
        Vendor represents a vendor of goods and services, like "Alan's Farm". It is tied
        to a product. Suma does a wholesale purchase from a vendor. It then lists those
        products, and takes responsibility for inventory and fulfillment.
      </Typography>
      <Box component="form" mt={2} onSubmit={handleSubmit(submit)}>
        <Stack spacing={2} direction="column" sx={{ width: { xs: "100%", sm: "75%" } }}>
          <TextField
            {...register("name")}
            label="Name"
            value={name}
            onChange={(e) => setName(e.target.value)}
          />
          <FormButtons back loading={isBusy} />
        </Stack>
      </Box>
    </div>
  );
}
