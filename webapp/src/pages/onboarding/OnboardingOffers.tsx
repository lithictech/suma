import useMountEffect from "../../state/useMountEffect.ts";
import useScreenLoader from "../../state/useScreenLoader.ts";
import BreadcrumbBack from "../../ui/BreadcrumbBack.tsx";
import ButtonGroup from "../../ui/ButtonGroup.tsx";
import Card from "../../ui/Card.tsx";
import CardBody from "../../ui/CardBody.tsx";
import ContinueButton from "../../ui/ContinueButton.tsx";
import DefinitionTable from "../../ui/DefinitionTable.tsx";
import Page from "../../ui/Page.tsx";
import ProgressStepHeader from "../../ui/ProgressStepHeader.tsx";
import { OnboardingProps } from "./onboardingTypes.ts";
import React from "react";

export default function OnboardingOffers({ onboardingState }: OnboardingProps) {
  const screenLoader = useScreenLoader();
  useMountEffect(screenLoader.turnOff);

  return (
    <Page buffer gap={3}>
      <ProgressStepHeader
        step={onboardingState.step}
        steps={onboardingState.totalSteps}
      />
      <BreadcrumbBack back />
      <h1>Thanks, Ana!</h1>
      <p>Your account is in review! But here are some offers you can use right away.</p>
      <Card>
        <CardBody>
          <DefinitionTable
            items={[
              { label: "Name", value: "Ana Flores" },
              { label: "Eligibility", value: "Hacienda CDC · In review" },
              { label: "Address", value: "2001 NE Alberta St, Portland, OR 97211" },
            ]}
          />
        </CardBody>
      </Card>
      <ButtonGroup col bottom>
        <ContinueButton to="/dashboard">Explore suma</ContinueButton>
      </ButtonGroup>
    </Page>
  );
}
