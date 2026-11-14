import { RoutePath } from "../routing/RoutePath.ts";
import Breadcrumb from "./Breadcrumb.tsx";
import Stack from "./Stack.tsx";
import "./TextHeader.css";
import clsx from "clsx";

export interface TextHeaderProps {
  backTo?: RoutePath;
  backLabel?: React.ReactNode;
  title: React.ReactNode;
  subtitle?: React.ReactNode;
  variant?: "page" | "section";
}

export default function TextHeader({
  backTo,
  backLabel,
  variant = "page",
  title,
  subtitle,
}: TextHeaderProps) {
  const H = variant === "page" ? "h1" : "h2";
  return (
    <Stack className={clsx("text-header", `text-header-${variant}`)} gap={4}>
      {backTo && <Breadcrumb to={backTo}>{backLabel}</Breadcrumb>}
      <H className="text-header-title">{title}</H>
      {subtitle && <p className="text-header-subtitle">{subtitle}</p>}
    </Stack>
  );
}
