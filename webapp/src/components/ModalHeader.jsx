import { t } from "../localization";
import React from "react";
import ModalHeaderBase from "react-bootstrap/ModalHeader";

/**
 * react-bootstrap's Modal.Header, with the close button labelled in the current
 * language. react-bootstrap's own default is the English "Close",
 * and it has no global setting for it. Pass closeLabel to override.
 */
const ModalHeader = React.forwardRef(function ModalHeader({ closeLabel, ...rest }, ref) {
  return (
    <ModalHeaderBase ref={ref} closeLabel={closeLabel ?? t("common.close")} {...rest} />
  );
});

export default ModalHeader;
