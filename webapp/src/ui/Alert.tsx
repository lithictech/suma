import { RoutePath } from "../routing/RoutePath.ts";
import "./Alert.css";
import DivLink from "./DivLink.tsx";
import Icon, { IconPropsIcon } from "./Icon.tsx";
import Stack from "./Stack.tsx";
import {
  BellAlertIcon,
  ExclamationTriangleIcon,
  HandThumbUpIcon,
} from "@heroicons/react/24/outline";
import clsx from "clsx";
import React from "react";

export type AlertVariant = "danger" | "success" | "warning" | "info";

export interface AlertProps {
  variant?: AlertVariant;
  text?: React.ReactNode;
  title?: React.ReactNode;
  to?: RoutePath;
  icon?: IconPropsIcon;
}

export default function Alert({ title, text, variant = "danger", to, icon }: AlertProps) {
  const cls = clsx("alert", `alert-${variant}`);
  icon = icon || variantIcons[variant];
  const content = (
    <Stack row gap={3} center>
      <Icon icon={icon} forceSize size="var(--alert-icon-size)" />
      <Stack col>
        {title && <div className="alert-title">{title}</div>}
        {text && <div className="alert-text">{text}</div>}
      </Stack>
    </Stack>
  );
  if (to) {
    return (
      <DivLink to={to} className={cls}>
        <Stack row center className="justify-content-between" gap={3}>
          {content}
          <Icon icon="right" size="var(--alert-arrow-size)" forceSize />
        </Stack>
      </DivLink>
    );
  }
  return <div className={cls}>{content}</div>;
}

const variantIcons: Record<AlertVariant, IconPropsIcon> = {
  danger: ExclamationTriangleIcon,
  warning: BellAlertIcon,
  success: HandThumbUpIcon,
  info: BellAlertIcon,
};
