import useI18n from "../localization/useI18n.ts";
import useBackendGlobals from "../state/useBackendGlobals.ts";
import CardText from "./CardText.tsx";
import RadioCard from "./RadioCard.tsx";
import Stack from "./Stack.tsx";

export default function LanguageSwitcher() {
  const { supportedLocales } = useBackendGlobals();
  const { currentLanguage, changeLanguage } = useI18n();
  if (!supportedLocales.items) {
    return null;
  }
  return (
    <Stack col gap={4}>
      <RadioCard
        name="language"
        options={supportedLocales.items.map(({ code, native }) => ({
          label: <CardText variant="subtitle">{native}</CardText>,
          value: code,
        }))}
        value={currentLanguage}
        onValueChange={(v) => changeLanguage(v)}
      />
    </Stack>
  );
}
