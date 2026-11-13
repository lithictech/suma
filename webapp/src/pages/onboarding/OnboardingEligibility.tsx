import AsyncContent from "../../components/AsyncContent.tsx";
import { AppError, extractAppErrorAny } from "../../modules/feedback.ts";
import useAsyncFetch from "../../state/useAsyncFetch.ts";
import useScreenLoader from "../../state/useScreenLoader.ts";
import useUser from "../../state/useUser.ts";
import Breadcrumb from "../../ui/Breadcrumb.tsx";
import ButtonGroup from "../../ui/ButtonGroup.tsx";
import CardBody from "../../ui/CardBody.tsx";
import CardText from "../../ui/CardText.tsx";
import CheckableCard from "../../ui/CheckableCard.tsx";
import ContinueButton from "../../ui/ContinueButton.tsx";
import Form from "../../ui/Form.tsx";
import FormFeedback from "../../ui/FormFeedback.tsx";
import Grid from "../../ui/Grid.tsx";
import Page from "../../ui/Page.tsx";
import ProgressStepHeader from "../../ui/ProgressStepHeader.tsx";
import TextHeader from "../../ui/TextHeader.tsx";
import Tile from "../../ui/Tile.tsx";
import { OnboardingProps } from "./onboardingTypes.ts";
import React from "react";

export default function OnboardingEligibility({
  apiCalls,
  onboardingState,
  setOnboardingField,
  stepForward,
  stepBackward,
}: OnboardingProps) {
  const { setUser } = useUser();
  const screenLoader = useScreenLoader();
  const [error, setError] = React.useState<AppError | null>();

  const {
    state: supportedOrganizations,
    loading: supportedOrgsLoading,
    error: supportedOrgsError,
  } = useAsyncFetch<{
    items: SupportedOrganization[];
  }>(apiCalls.getSupportedOrganizations, {
    default: { items: [] },
  });

  function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    screenLoader.turnOn();
    apiCalls
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
      <Breadcrumb onClick={stepBackward} />
      <ProgressStepHeader
        step={onboardingState.step}
        steps={onboardingState.totalSteps}
      />
      <TextHeader
        title="Do you have any eligibility?"
        subtitle="Tell us which organizations you’re affiliate with. This helps us determine your
        eligibility for different offerings."
      />
      <Form noValidate onSubmit={handleSubmit}>
        <p className="mb-5">Choose an organization:</p>
        <AsyncContent loading={supportedOrgsLoading} error={supportedOrgsError}>
          {() => (
            <Grid columns={2} gap={4}>
              {supportedOrganizations.items.map(({ name, initials, description }) => (
                <CheckableCard
                  key={name}
                  checked={onboardingState.organizationNames.includes(name)}
                  className="h-100"
                  onChange={() =>
                    setOnboardingField(
                      "organizationNames",
                      toggleEntry(onboardingState.organizationNames, name)
                    )
                  }
                >
                  <CardBody className="d-flex gap-2 flex-column">
                    <Tile>{initials}</Tile>
                    <CardText variant="title">{name}</CardText>
                    <CardText variant="text">{description}</CardText>
                  </CardBody>
                </CheckableCard>
              ))}
            </Grid>
          )}
        </AsyncContent>
        <FormFeedback feedback={error} />
        <ButtonGroup col bottom>
          <ContinueButton />
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
