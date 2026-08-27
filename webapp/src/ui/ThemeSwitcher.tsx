import useLocalStorageState from "../state/useLocalStorageState.ts";
import useMountEffect from "../state/useMountEffect.ts";
import CardText from "./CardText.tsx";
import RadioCard from "./RadioCard.tsx";
import Stack from "./Stack.tsx";

export type Theme = "system" | "light" | "dark";
export type Contrast = "default" | "high";

export default function ThemeSwitcher() {
  const [theme, setThemeState] = useLocalStorageState<Theme>("theme", "system");
  const [contrast, setContrastState] = useLocalStorageState<Contrast>(
    "contrast",
    "default"
  );

  useMountEffect(() => {
    setThemeOnDOM(theme, contrast);
  });

  function handleTheme(t: Theme) {
    setThemeState(t);
    setThemeOnDOM(t, contrast);
  }

  function handleContrast(c: Contrast) {
    setContrastState(c);
    setThemeOnDOM(theme, c);
  }

  return (
    <Stack col gap={4}>
      <h4>Appearance</h4>
      <RadioCard<Theme>
        name="theme"
        options={[
          {
            label: (
              <div>
                <CardText variant="subtitle">Light</CardText>
                <CardText variant="subtext">Always use the light theme</CardText>
              </div>
            ),
            value: "light",
          },
          {
            label: (
              <div>
                <CardText variant="subtitle">Dark</CardText>
                <CardText variant="subtext">Always use the dark theme</CardText>
              </div>
            ),
            value: "dark",
          },
          {
            label: (
              <div>
                <CardText variant="subtitle">System</CardText>
                <CardText variant="subtext">Use whatever your system is set to.</CardText>
              </div>
            ),
            value: "system",
          },
        ]}
        value={theme}
        onValueChange={handleTheme}
      />
      <h4>Contrast</h4>
      <RadioCard<Contrast>
        name="contrast"
        options={[
          {
            label: (
              <div>
                <CardText variant="subtitle">Default</CardText>
                <CardText variant="subtext">Standard text and border strength</CardText>
              </div>
            ),
            value: "default",
          },
          {
            label: (
              <div>
                <CardText variant="subtitle">High Contrast</CardText>
                <CardText variant="subtext">
                  Stronger borders, dividers, larger text
                </CardText>
              </div>
            ),
            value: "high",
          },
        ]}
        value={contrast}
        onValueChange={handleContrast}
      />
    </Stack>
  );
}

function setThemeOnDOM(t: Theme, c: Contrast) {
  if (t === "system") {
    const prefersDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
    t = prefersDark ? "dark" : "light";
  }
  document.documentElement.setAttribute("data-theme", t);
  document.documentElement.setAttribute("data-contrast", c);
}
