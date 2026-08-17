import BackButton from "../../ui/BackButton.tsx";
import BreadcrumbBack from "../../ui/BreadcrumbBack.tsx";
import ButtonGroup from "../../ui/ButtonGroup.tsx";
import ContinueButton from "../../ui/ContinueButton.tsx";
import Page from "../../ui/Page.tsx";
import ThemeSwitcher from "../../ui/ThemeSwitcher.tsx";
import React from "react";

export default function OnboardingTheme() {
  return (
    <Page buffer gap={3}>
      <BreadcrumbBack back />
      <h1>How should the app look?</h1>
      <p>Pick what&rsquo;s easier to read. You can change it later!</p>
      <ThemeSwitcher />
      <ButtonGroup col bottom>
        <ContinueButton to="/onboarding/name" />
        <BackButton to="/onboarding" />
      </ButtonGroup>
    </Page>
  );
}
