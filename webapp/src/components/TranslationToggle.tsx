import useI18n from "../localization/useI18n";
import clearHashFunc from "../routing/clearHash.ts";
import useBackendGlobals from "../state/useBackendGlobals.ts";
import { Direction } from "../types/direction.ts";
import LanguageSwitcher from "../ui/LanguageSwitcher.tsx";
import React, { CSSProperties } from "react";
import { useLocation, useNavigate } from "react-router-dom";

interface TranslationToggleProps {
  className?: string;
  style?: CSSProperties;
  direction?: Direction;
  clearHash?: boolean;
}

export default function TranslationToggle({
  direction,
  className,
  style,
  clearHash,
}: TranslationToggleProps) {
  const { currentLanguage, changeLanguage } = useI18n();
  const { supportedLocales } = useBackendGlobals();
  const location = useLocation();
  const navigate = useNavigate();

  const changeLang = React.useCallback(
    (lang: string) => {
      if (clearHash && location.hash) {
        // When we change the language, the components rebuild.
        // If we are scrolling on mount, this causes us to re-scroll.
        // It seems reasonable to clear the hash globally,
        // but if this is a problem,
        clearHashFunc(location, navigate);
      }
      return changeLanguage(lang);
    },
    [changeLanguage, clearHash, location, navigate]
  );

  return (
    <LanguageSwitcher
      supportedLocales={supportedLocales?.items || []}
      currentLanguage={currentLanguage}
      changeLanguage={changeLang}
      direction={direction}
      className={className}
      style={style}
    />
  );
}
