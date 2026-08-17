import BreadcrumbBack from "../../ui/BreadcrumbBack.tsx";
import ButtonGroup from "../../ui/ButtonGroup.tsx";
import Checklist from "../../ui/Checklist.tsx";
import ChecklistItem from "../../ui/ChecklistItem.tsx";
import ContinueButton from "../../ui/ContinueButton.tsx";
import Page from "../../ui/Page.tsx";
import React from "react";

export default function Onboarding() {
  return (
    <Page buffer gap={3}>
      <BreadcrumbBack back />
      <h1>Let&rsquo;s get you set up</h1>
      <p>It only takes a few minutes. Here’s what we’ll ask for:</p>
      <Checklist>
        <ChecklistItem step={1}>How the app looks</ChecklistItem>
        <ChecklistItem step={2}>Your name</ChecklistItem>
        <ChecklistItem step={3}>Your home address</ChecklistItem>
        <ChecklistItem step={4}>Your eligibility</ChecklistItem>
        <ChecklistItem step={5}>Offers you can use</ChecklistItem>
      </Checklist>
      <ButtonGroup col bottom>
        <ContinueButton to="/onboarding/theme" />
      </ButtonGroup>
    </Page>
  );
}
