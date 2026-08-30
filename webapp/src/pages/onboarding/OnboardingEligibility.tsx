import api from "../../api.ts";
import { extractAppErrorAny } from "../../modules/errors.ts";
import useAsyncFetch from "../../state/useAsyncFetch.ts";
import useError from "../../state/useError.tsx";
import useScreenLoader from "../../state/useScreenLoader.ts";
import useUser from "../../state/useUser.ts";
import BackButton from "../../ui/BackButton.tsx";
import BreadcrumbBack from "../../ui/BreadcrumbBack.tsx";
import ButtonGroup from "../../ui/ButtonGroup.tsx";
import CardBody from "../../ui/CardBody.tsx";
import CardText from "../../ui/CardText.tsx";
import CheckableCard from "../../ui/CheckableCard.tsx";
import ContinueButton from "../../ui/ContinueButton.tsx";
import Form from "../../ui/Form.tsx";
import FormError from "../../ui/FormError.tsx";
import Grid from "../../ui/Grid.tsx";
import Page from "../../ui/Page.tsx";
import ProgressStepHeader from "../../ui/ProgressStepHeader.tsx";
import Tile from "../../ui/Tile.tsx";
import { OnboardingProps } from "./onboardingTypes.ts";
import React from "react";

export default function OnboardingEligibility({
  onboardingState,
  setOnboardingField,
  stepForward,
  stepBackward,
}: OnboardingProps) {
  const { setUser } = useUser();
  const screenLoader = useScreenLoader();
  const [error, setError] = useError();

  const { state: supportedOrganizations } = useAsyncFetch<{
    items: SupportedOrganization[];
  }>(api.getSupportedOrganizations, {
    default: { items: [] },
  });

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    screenLoader.turnOn();
    api
      .onboard({
        name: onboardingState.name,
        address: onboardingState.address,
        organizationNames: onboardingState.organizationNames,
      })
      .then((r) => {
        setUser(r.data.member);
        setOnboardingField("onboarded", r.data);
        stepForward();
      })
      .catch((err) => {
        setError(extractAppErrorAny(err));
        screenLoader.turnOff();
      });
  }

  return (
    <Page>
      <ProgressStepHeader
        step={onboardingState.step}
        steps={onboardingState.totalSteps}
      />
      <BreadcrumbBack back />
      <h1>Do you have any eligibility?</h1>
      <p>
        Tell us which organizations you’re affiliate with. This helps us determine your
        eligibility for different offerings.
      </p>
      <Form noValidate onSubmit={handleSubmit}>
        <p>Choose an organization:</p>
        <Grid columns={2} gap={2}>
          {supportedOrganizations.items.map(({ name }) => (
            <CheckableCard
              key={name}
              checked={onboardingState.organizationNames.includes(name)}
              onChange={() =>
                setOnboardingField(
                  "organizationNames",
                  toggleEntry(onboardingState.organizationNames, name)
                )
              }
            >
              <CardBody className="d-flex gap-2 flex-column">
                <Tile>RC</Tile>
                <CardText variant="title">{name}</CardText>
                <CardText variant="text">Affordable housing</CardText>
              </CardBody>
            </CheckableCard>
          ))}
        </Grid>
        <FormError error={error} />
        <ButtonGroup col bottom>
          <ContinueButton />
          <BackButton onClick={stepBackward} />
        </ButtonGroup>
      </Form>
    </Page>
  );
}

function toggleEntry<T>(items: T[], v: T): T[] {
  const idx = items.indexOf(v);
  if (idx === -1) {
    return [...items, v];
  }
  return items.toSpliced(idx, 1);
}
