import { t } from "../localization";
import Button, { ButtonProps } from "./Button.tsx";
import React from "react";

const BackButton = React.forwardRef<HTMLButtonElement | HTMLAnchorElement, ButtonProps>(
  function ({ children, variant, onClick, to, ...rest }: ButtonProps, ref) {
    children = children || t("common.back");
    variant = variant || "secondary";
    if (!to && !onClick) {
      onClick = () => window.history.back();
    }
    return (
      <Button ref={ref} variant={variant} onClick={onClick} to={to} {...rest}>
        {children}
      </Button>
    );
  }
);

export default BackButton;
