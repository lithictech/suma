import Page from "../ui/Page.tsx";
import PageHeader from "../ui/PageHeader.tsx";
import ThemeSwitcher from "../ui/ThemeSwitcher.tsx";

export default function ThemePage() {
  return (
    <Page appNav>
      <PageHeader back title="Theme" />
      <ThemeSwitcher />
    </Page>
  );
}
