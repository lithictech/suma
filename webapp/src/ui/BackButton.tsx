import { t } from "../localization";
import Button, { ButtonProps } from "./Button.tsx";
import React from "react";

const BackButton = React.forwardRef<HTMLButtonElement | HTMLAnchorElement, ButtonProps>(
  function ({ children, variant, onClick }: ButtonProps, ref) {
    children = children || t("common.back");
    variant = variant || "secondary";
    onClick = onClick || (() => window.history.back());
    return (
      <Button ref={ref} variant={variant} onClick={onClick}>
        {children}
      </Button>
    );
  }
);

export default BackButton;
