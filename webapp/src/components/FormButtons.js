import { t } from "../localization";
import clsx from "clsx";
import React from "react";
import Button from "react-bootstrap/Button";

const FormButtons = ({ primaryProps, secondaryProps, variant, back, className }) => {
  if (back) {
    secondaryProps = {
      children: t("common:back"),
      onClick: () => window.history.back(),
    };
  }
  variant = variant || "primary";
  return (
    <div className={clsx("d-flex flex-row justify-content-end", className)}>
      {secondaryProps && <Button variant={`outline-${variant}`} {...secondaryProps} />}
      {primaryProps && (
        <Button variant={variant} className="ms-2" type="submit" {...primaryProps} />
      )}
    </div>
  );
};
export default FormButtons;
