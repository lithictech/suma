import { RoutePath } from "../routing/RoutePath.ts";
import { TintColor } from "../types/theme";
import "./Alert.css";
import DivLink from "./DivLink.tsx";
import Icon, { IconPropsIcon } from "./Icon.tsx";
import Stack from "./Stack.tsx";
import { BellAlertIcon } from "@heroicons/react/24/outline";
import clsx from "clsx";
import React from "react";

export interface AlertProps {
  variant?: TintColor;
  text?: React.ReactNode;
  title?: React.ReactNode;
  to?: RoutePath;
  icon?: IconPropsIcon;
}

export default function Alert({
  title,
  text,
  variant = "primary",
  to,
  icon = BellAlertIcon,
}: AlertProps) {
  const cls = clsx("alert", `alert-${variant}`);
  const content = (
    <Stack row gap={3} center>
      <Icon icon={icon} />
      <Stack col>
        {title && <div className="alert-title">{title}</div>}
        {text && <div className="alert-text">{text}</div>}
      </Stack>
    </Stack>
  );
  if (to) {
    return (
      <DivLink to={to} className={cls}>
        <Stack row center className="justify-content-between">
          {content}
          <Icon icon="right" />
        </Stack>
      </DivLink>
    );
  }
  return <div className={cls}>{content}</div>;
}
