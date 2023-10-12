import extractErrorMessage from "../modules/extractErrorMessage";
import { useSnackbar } from "notistack";
import React from "react";

export default function useErrorSnackbar() {
  const { enqueueSnackbar, closeSnackbar } = useSnackbar();
  const enqueueErrorSnackbar = React.useCallback(
    (e, options) => {
      options = options || { variant: "error" };
      enqueueSnackbar(extractErrorMessage(e), options);
    },
    [enqueueSnackbar]
  );
  return { enqueueErrorSnackbar, closeSnackbar };
}
