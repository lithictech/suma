import api from "../api";
import FormButtons from "../components/FormButtons";
import useBusy from "../hooks/useBusy";
import useErrorSnackbar from "../hooks/useErrorSnackbar";
import { Stack, TextField, Typography } from "@mui/material";
import Box from "@mui/material/Box";
import React from "react";
import { useForm } from "react-hook-form";
import { useNavigate } from "react-router-dom";

export default function EligibilityConstraintCreatePage() {
  const navigate = useNavigate();
  const nameInput = React.useRef("");
  const { enqueueErrorSnackbar } = useErrorSnackbar();
  const { isBusy, busy, notBusy } = useBusy();
  const { register, handleSubmit } = useForm();
  const submit = () => {
    busy();
    api
      .createEligibilityConstraint({ name: nameInput.current.value })
      .then(api.followRedirect(navigate))
      .tapCatch(notBusy)
      .catch(enqueueErrorSnackbar);
  };
  return (
    <div style={{ maxWidth: 650 }}>
      <Typography variant="h4" gutterBottom>
        Create an Eligibility Constraint
      </Typography>
      <Typography variant="body1" gutterBottom>
        Constraints describe who can access a service. For example, if you set a
        constraint to an Offering only members with the same constraint can access it.
      </Typography>
      <Box component="form" mt={2} onSubmit={handleSubmit(submit)}>
        <Stack spacing={2}>
          <TextField
            {...register("name")}
            inputRef={nameInput}
            label="Name"
            type="name"
            variant="outlined"
            fullWidth
            required
          />
          <FormButtons back loading={isBusy} />
        </Stack>
      </Box>
    </div>
  );
}
