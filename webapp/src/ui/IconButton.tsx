import "./Button.css";
import Button, { ButtonProps, ButtonSize } from "./Button.tsx";
import Icon, { IconPropsIcon } from "./Icon.tsx";
import "./IconButton.css";
import clsx from "clsx";
import React from "react";

export interface IconButtonProps extends ButtonProps {
  icon: IconPropsIcon;
}

const IconButton = React.forwardRef<
  HTMLButtonElement | HTMLAnchorElement,
  IconButtonProps
>(function IconButton({ icon, size = "md", className, ...rest }, ref) {
  return (
    <div>
      <Button className={clsx("icon-button", className)} size={size} {...rest} ref={ref}>
        <Icon icon={icon} size={iconSizes[size]} />
      </Button>
    </div>
  );
});

const iconSizes: Record<ButtonSize, number> = {
  sm: 16,
  md: 24,
  lg: 32,
};

export default IconButton;
