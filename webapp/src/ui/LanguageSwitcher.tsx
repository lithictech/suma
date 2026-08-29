import CardText from "./CardText.tsx";
import RadioCard from "./RadioCard.tsx";
import Stack from "./Stack.tsx";

interface LanguageSwitcherProps {
  supportedLocales: Locale[];
  currentLanguage: string;
  changeLanguage: (language: string) => void;
}
export default function LanguageSwitcher({
  supportedLocales,
  currentLanguage,
  changeLanguage,
}: LanguageSwitcherProps) {
  if (!supportedLocales) {
    return null;
  }
  return (
    <Stack col gap={4}>
      <RadioCard
        name="language"
        options={supportedLocales.map(({ code, native }) => ({
          label: <CardText variant="subtitle">{native}</CardText>,
          value: code,
        }))}
        value={currentLanguage}
        onValueChange={(v) => changeLanguage(v)}
      />
    </Stack>
  );
}
