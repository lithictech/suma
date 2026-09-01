import { Direction } from "../types/direction.ts";
import CardText from "./CardText.tsx";
import Icon from "./Icon.tsx";
import RadioCard from "./RadioCard.tsx";
import LanguageIcon from "@heroicons/react/24/outline/LanguageIcon";
import clsx from "clsx";
import React from "react";

export type LanguageSwitcherVariant = "horizontal" | "vertical" | "short";

interface LanguageSwitcherProps {
  supportedLocales: Locale[];
  currentLanguage: string;
  changeLanguage: (language: string) => void;
  variant?: LanguageSwitcherVariant;
  className?: string;
  style?: React.CSSProperties;
}

export default function LanguageSwitcher({
  supportedLocales,
  currentLanguage,
  changeLanguage,
  variant = "horizontal",
  className,
  style,
}: LanguageSwitcherProps) {
  if (!supportedLocales) {
    return null;
  }
  let direction: Direction = "horizontal";
  if (variant === "vertical") {
    direction = "vertical";
  }
  return (
    <RadioCard
      name="language"
      direction={direction}
      options={supportedLocales.map(({ code, native }) => ({
        label: (
          <CardText variant="subtitle">
            <Icon
              icon={LanguageIcon}
              className={clsx("mr-2", code !== currentLanguage && "hidden")}
            />
            {native}
          </CardText>
        ),
        value: code,
      }))}
      value={currentLanguage}
      optionClass={variant === "short" ? "py-1 px-0" : ""}
      className={className}
      style={style}
      onValueChange={(v) => changeLanguage(v)}
    />
  );
}
