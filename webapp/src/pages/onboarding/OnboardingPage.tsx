import api from "../../api.ts";
import Onboarding from "./Onboarding.tsx";
import { OnboardingApiCalls } from "./onboardingTypes.ts";

export default function OnboardingPage() {
  return <Onboarding apiCalls={apiCalls} />;
}

const apiCalls: OnboardingApiCalls = {
  getSupportedGeographies: api.getSupportedGeographies,
  getSupportedOrganizations: api.getSupportedOrganizations,
  onboard: api.onboard,
};
