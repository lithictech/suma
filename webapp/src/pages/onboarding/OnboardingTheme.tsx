import BackButton from "../../ui/BackButton.tsx";
import BreadcrumbBack from "../../ui/BreadcrumbBack.tsx";
import ButtonGroup from "../../ui/ButtonGroup.tsx";
import ContinueButton from "../../ui/ContinueButton.tsx";
import Page from "../../ui/Page.tsx";
import ProgressStepHeader from "../../ui/ProgressStepHeader.tsx";
import ThemeSwitcher from "../../ui/ThemeSwitcher.tsx";
import { OnboardingProps } from "./onboardingTypes.ts";

export default function OnboardingTheme({
  onboardingState,
  stepForward,
  stepBackward,
}: OnboardingProps) {
  return (
    <Page buffer gap={3}>
      <ProgressStepHeader
        step={onboardingState.step}
        steps={onboardingState.totalSteps}
      />
      <BreadcrumbBack back />
      <h1>How should the app look?</h1>
      <p>Pick what&rsquo;s easier to read. You can change it later!</p>
      <ThemeSwitcher />
      <ButtonGroup col bottom>
        <ContinueButton onClick={stepForward} />
        <BackButton onClick={stepBackward} />
      </ButtonGroup>
    </Page>
  );
}
