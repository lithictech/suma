import { t } from "../localization";
import Button, { ButtonProps } from "./Button.tsx";
import React from "react";

const BackButton = React.forwardRef<HTMLButtonElement | HTMLAnchorElement, ButtonProps>(
  function ({ children, variant, onClick, to, href, ...rest }: ButtonProps, ref) {
    children = children || t("common.back");
    variant = variant || "secondary";
    if (!to && !href && !onClick) {
      onClick = () => window.history.back();
    }
    return (
      <Button ref={ref} variant={variant} onClick={onClick} to={to} href={href} {...rest}>
        {children}
      </Button>
    );
  }
);

export default BackButton;
