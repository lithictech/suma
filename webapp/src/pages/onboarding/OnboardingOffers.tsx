import ProgramCard from "../../components/ProgramCard.tsx";
import { t } from "../../localization";
import useMountEffect from "../../state/useMountEffect.ts";
import useScreenLoader from "../../state/useScreenLoader.ts";
import ButtonGroup from "../../ui/ButtonGroup.tsx";
import Card from "../../ui/Card.tsx";
import CardBody from "../../ui/CardBody.tsx";
import ContinueButton from "../../ui/ContinueButton.tsx";
import DefinitionTable from "../../ui/DefinitionTable.tsx";
import Page from "../../ui/Page.tsx";
import ProgressStepHeader from "../../ui/ProgressStepHeader.tsx";
import { OnboardingProps } from "./onboardingTypes.ts";

export default function OnboardingOffers({ onboardingState }: OnboardingProps) {
  const screenLoader = useScreenLoader();
  useMountEffect(screenLoader.turnOff);

  const { onboarded } = onboardingState;

  return (
    <Page buffer gap={3}>
      <ProgressStepHeader
        step={onboardingState.step}
        steps={onboardingState.totalSteps}
      />
      <h1>Thanks, {onboarded.member.name}!</h1>
      <p>Your account is in review! But here are some offers you can use right away.</p>
      <Card>
        <CardBody>
          <DefinitionTable
            items={[
              { label: "Name", value: onboarded.member.name },
              {
                label: "Eligibility",
                value: eligibiltyValueString(onboarded.memberships[0]),
              },
              { label: "Address", value: onboarded.address.oneLineAddress },
            ]}
          />
        </CardBody>
      </Card>
      {onboarded.programs.map((program) => (
        <ProgramCard key={program.name} {...program} />
      ))}
      <ButtonGroup col bottom>
        <ContinueButton to="/dashboard">Explore suma</ContinueButton>
      </ButtonGroup>
    </Page>
  );
}

function eligibiltyValueString(membership: Membership) {
  const status = t(`verification.status.${membership.status}`);
  return `${membership.organizationName} · ${status}`;
}
