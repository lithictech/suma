import LoadingButton from "@mui/lab/LoadingButton";
import { Stack } from "@mui/material";
import Button from "@mui/material/Button";
import _ from "lodash";
import React from "react";

const FormButtons = ({ primaryProps, secondaryProps, back, loading }) => {
  if (back) {
    secondaryProps = {
      children: "Back",
      onClick: () => window.history.back(),
    };
  }
  primaryProps = _.merge({ children: "Submit", variant: "contained" }, primaryProps);
  return (
    <Stack direction="row" spacing={2} justifyContent="flex-end">
      {secondaryProps && <Button {...secondaryProps} />}
      {primaryProps && (
        <LoadingButton type="submit" loading={loading} {...primaryProps} />
      )}
    </Stack>
  );
};
export default FormButtons;
