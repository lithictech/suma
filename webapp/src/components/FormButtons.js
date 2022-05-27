import clsx from "clsx";
import i18next from "i18next";
import React from "react";
import Button from "react-bootstrap/Button";

const FormButtons = ({ primaryProps, secondaryProps, variant, back, className }) => {
  if (back) {
    secondaryProps = {
      children: i18next.t("back", { ns: "forms" }),
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
