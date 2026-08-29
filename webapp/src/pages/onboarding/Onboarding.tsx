import ButtonGroup from "../../ui/ButtonGroup.tsx";
import Checklist from "../../ui/Checklist.tsx";
import ChecklistItem from "../../ui/ChecklistItem.tsx";
import ContinueButton from "../../ui/ContinueButton.tsx";
import Page from "../../ui/Page.tsx";
import OnboardingAddress from "./OnboardingAddress.tsx";
import OnboardingEligibility from "./OnboardingEligibility.tsx";
import OnboardingName from "./OnboardingName.tsx";
import OnboardingOffers from "./OnboardingOffers.tsx";
import OnboardingTheme from "./OnboardingTheme.tsx";
import { OnboardingProps, OnboardingState } from "./onboardingTypes.ts";
import React from "react";

export default function Onboarding() {
  const [state, setState] = React.useState<OnboardingState>({
    step: 0,
    totalSteps: 5,
    address: {
      address1: "",
      address2: "",
      city: "",
      stateOrProvince: "",
      postalCode: "",
    },
    name: "",
    organizationNames: [],
  });
  const props: OnboardingProps = React.useMemo(
    () => ({
      onboardingState: state,
      setOnboardingState: setState,
      setOnboardingField: (f: string, v: any) =>
        setState((prev) => ({ ...prev, [f]: v })),
      stepForward: () => setState((prev) => ({ ...prev, step: prev.step + 1 })),
      stepBackward: () => setState((prev) => ({ ...prev, step: prev.step - 1 })),
    }),
    [state]
  );
  if (state.step === 0) {
    return <OnboardingStep0 {...props} />;
  } else if (state.step === 1) {
    return <OnboardingTheme {...props} />;
  } else if (state.step === 2) {
    return <OnboardingName {...props} />;
  } else if (state.step === 3) {
    return <OnboardingAddress {...props} />;
  } else if (state.step === 4) {
    return <OnboardingEligibility {...props} />;
  } else {
    return <OnboardingOffers {...props} />;
  }
}

function OnboardingStep0({ stepForward }: OnboardingProps) {
  return (
    <Page>
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
        <ContinueButton onClick={stepForward} />
      </ButtonGroup>
    </Page>
  );
}
