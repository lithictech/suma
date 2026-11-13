import Breadcrumb from "../../ui/Breadcrumb.tsx";
import ButtonGroup from "../../ui/ButtonGroup.tsx";
import ContinueButton from "../../ui/ContinueButton.tsx";
import Page from "../../ui/Page.tsx";
import ProgressStepHeader from "../../ui/ProgressStepHeader.tsx";
import TextHeader from "../../ui/TextHeader.tsx";
import ThemeSwitcher from "../../ui/ThemeSwitcher.tsx";
import { OnboardingProps } from "./onboardingTypes.ts";

export default function OnboardingTheme({
  onboardingState,
  stepForward,
  stepBackward,
}: OnboardingProps) {
  return (
    <Page>
      <Breadcrumb onClick={stepBackward} />
      <ProgressStepHeader
        step={onboardingState.step}
        steps={onboardingState.totalSteps}
      />
      <TextHeader
        title="How should the app look?"
        subtitle="Pick what&rsquo;s easier to read. You can change it later!"
      />
      <ThemeSwitcher />
      <ButtonGroup col bottom>
        <ContinueButton onClick={stepForward} />
      </ButtonGroup>
    </Page>
  );
}
