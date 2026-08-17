import BreadcrumbBack from "../../ui/BreadcrumbBack.tsx";
import ButtonGroup from "../../ui/ButtonGroup.tsx";
import ContinueButton from "../../ui/ContinueButton.tsx";
import Page from "../../ui/Page.tsx";
import React from "react";

export default function OnboardingName() {
  return (
    <Page buffer gap={3}>
      <BreadcrumbBack back />
      <h1>What is your name?</h1>
      <p>We&rsquo;d love to know what to call you!</p>

      <ButtonGroup col bottom>
        <ContinueButton to="/onboarding/address" />
      </ButtonGroup>
    </Page>
  );
}
