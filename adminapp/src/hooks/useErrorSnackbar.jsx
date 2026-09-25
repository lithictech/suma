import extractErrorMessage from "../modules/extractErrorMessage";
import isNil from "lodash/isNil";
import { useSnackbar } from "notistack";
import React from "react";

export default function useErrorSnackbar() {
  const { enqueueSnackbar, closeSnackbar } = useSnackbar();
  const enqueueErrorSnackbar = React.useCallback(
    (e, options = {}) => {
      options = options || {};
      options.variant = options.variant || "error";
      if (isNil(options.persist) && isNil(options.autoHideDuration)) {
        // Errors stay until dismissed, so they are not missed.
        options.persist = true;
      }
      enqueueSnackbar(extractErrorMessage(e), options);
    },
    [enqueueSnackbar]
  );
  return { enqueueErrorSnackbar, closeSnackbar };
}
