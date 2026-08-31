import { Direction } from "../types/direction.ts";
import CardText from "./CardText.tsx";
import RadioCard from "./RadioCard.tsx";
import React from "react";

interface LanguageSwitcherProps {
  supportedLocales: Locale[];
  currentLanguage: string;
  changeLanguage: (language: string) => void;
  direction?: Direction;
  className?: string;
  style?: React.CSSProperties;
}

export default function LanguageSwitcher({
  supportedLocales,
  currentLanguage,
  changeLanguage,
  direction = "horizontal",
  className,
  style,
}: LanguageSwitcherProps) {
  if (!supportedLocales) {
    return null;
  }
  return (
    <RadioCard
      name="language"
      direction={direction}
      options={supportedLocales.map(({ code, native }) => ({
        label: <CardText variant="subtitle">{native}</CardText>,
        value: code,
      }))}
      value={currentLanguage}
      className={className}
      style={style}
      onValueChange={(v) => changeLanguage(v)}
    />
  );
}
