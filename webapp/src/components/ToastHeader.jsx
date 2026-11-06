import { t } from "../localization";
import React from "react";
import ToastHeaderBase from "react-bootstrap/ToastHeader";

/**
 * react-bootstrap's Toast.Header, with the close button labelled in the current
 * language. react-bootstrap's own default is the English "Close",
 * and it has no global setting for it. Pass closeLabel to override.
 */
const ToastHeader = React.forwardRef(function ToastHeader({ closeLabel, ...rest }, ref) {
  return (
    <ToastHeaderBase ref={ref} closeLabel={closeLabel ?? t("common.close")} {...rest} />
  );
});

export default ToastHeader;
