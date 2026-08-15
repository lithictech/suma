import { t } from "../localization";
import useI18n from "../localization/useI18n";
import Button from "../ui/Button";
import Icon from "../ui/Icon.tsx";
import LanguageIcon from "@heroicons/react/24/outline/LanguageIcon";
import React from "react";

export default function TranslationToggle({ className }: { className?: string }) {
  const { currentLanguage } = useI18n();
  return currentLanguage !== "en" ? (
    <Translate
      className={className}
      to="en"
      label={t("common.in_english")}
      title={t("common.translate_to_english")}
    />
  ) : (
    <Translate
      className={className}
      to="es"
      label={t("common.in_spanish")}
      title={t("common.translate_to_spanish")}
    />
  );
}

interface TranslateProps {
  className: string;
  to: string;
  label: React.ReactNode;
  title: string;
}

const Translate = ({ className, to, label, title }: TranslateProps) => {
  const { changeLanguage } = useI18n();
  return (
    <Button
      className={className}
      variant="text"
      onClick={() => changeLanguage(to)}
      title={title}
    >
      <Icon icon={LanguageIcon} /> <i>{label}</i>
    </Button>
  );
};
