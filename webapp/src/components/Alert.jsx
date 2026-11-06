import { t } from "../localization";
import React from "react";
import BootstrapAlert from "react-bootstrap/Alert";

/**
 * react-bootstrap's Alert, with the dismiss button labelled in the current
 * language. react-bootstrap's own default is the English "Close alert",
 * and it has no global setting for it. Pass closeLabel to override.
 */
const Alert = React.forwardRef(function Alert({ closeLabel, ...rest }, ref) {
  return (
    <BootstrapAlert ref={ref} closeLabel={closeLabel ?? t("common.close")} {...rest} />
  );
});

Alert.Heading = BootstrapAlert.Heading;
Alert.Link = BootstrapAlert.Link;

export default Alert;
