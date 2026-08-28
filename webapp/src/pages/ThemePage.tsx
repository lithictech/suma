import AppNav from "../components/AppNav.tsx";
import Page from "../ui/Page.tsx";
import PageHeader from "../ui/PageHeader.tsx";
import ThemeSwitcher from "../ui/ThemeSwitcher.tsx";

export default function ThemePage() {
  return (
    <Page>
      <Page buffer gap={3}>
        <PageHeader back title="Theme" />
        <ThemeSwitcher />
      </Page>
      <AppNav />
    </Page>
  );
}
