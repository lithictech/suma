import Home from "../pages/onboarding/Home.tsx";
import Onboarding from "../pages/onboarding/Onboarding.tsx";
import OnboardingAddress from "../pages/onboarding/OnboardingAddress.tsx";
import OnboardingEligibility from "../pages/onboarding/OnboardingEligibility.tsx";
import OnboardingName from "../pages/onboarding/OnboardingName.tsx";
import OnboardingOffers from "../pages/onboarding/OnboardingOffers.tsx";
import OnboardingTheme from "../pages/onboarding/OnboardingTheme.tsx";
import OneTimePassword from "../pages/onboarding/OneTimePassword.tsx";
import Start from "../pages/onboarding/Start.tsx";
import {
  OnboardingApiCalls,
  useOnboardingProps,
} from "../pages/onboarding/onboardingTypes.ts";
import {
  address,
  axiosErrorMocker,
  axiosResponseMocker,
  currentMember,
  organizationMembership,
  program,
} from "./fixtures.ts";
import type { Meta, StoryObj } from "@storybook/preact-vite";
import noop from "lodash/noop";

const meta = {
  title: "Styleguide/Onboarding",
  parameters: { layout: "fullscreen" },
} satisfies Meta;

export default meta;
type Story = StoryObj<typeof meta>;

export const HomePage: Story = {
  render: () => <Home />,
};

export const StartPageSuccess: Story = {
  render: () => (
    <Start
      apiCalls={{
        authStart: axiosResponseMocker<AuthFlowMember>({ requiresTermsAgreement: false }),
      }}
    />
  ),
};

export const StartPageError: Story = {
  render: () => (
    <Start
      apiCalls={{
        authStart: axiosErrorMocker<AuthFlowMember>(),
      }}
    />
  ),
};

const otpInitialEntries = [{ pathname: "/", state: { phoneNumber: "+15551234567" } }];
const otpApiCalls = {
  authVerify: axiosResponseMocker<CurrentMember>(currentMember()),
  authStart: axiosResponseMocker<AuthFlowMember>({
    requiresTermsAgreement: false,
  }),
};
export const OneTimePasswordSuccess: Story = {
  parameters: {
    initialEntries: otpInitialEntries,
  },
  render: () => <OneTimePassword setUser={noop} apiCalls={otpApiCalls} />,
};

export const OneTimePasswordResend: Story = {
  parameters: {
    initialEntries: otpInitialEntries,
  },
  render: () => <OneTimePassword setUser={noop} apiCalls={otpApiCalls} />,
};

export const OneTimePasswordError: Story = {
  parameters: {
    initialEntries: otpInitialEntries,
  },
  render: () => (
    <OneTimePassword
      setUser={noop}
      apiCalls={{
        ...otpApiCalls,
        authVerify: axiosErrorMocker<CurrentMember>(),
        authStart: axiosErrorMocker<AuthFlowMember>(),
      }}
    />
  ),
};

const onboardingApiCalls: OnboardingApiCalls = {
  getSupportedGeographies: axiosResponseMocker({
    countries: [
      { label: "United States", value: "usa" },
      { label: "Mexico", value: "mx" },
    ],
    provinces: [
      { label: "Oregon", value: "or", countryIdx: 0 },
      { label: "Washing", value: "wa", countryIdx: 0 },
      { label: "Mexico City", value: "mcty", countryIdx: 1 },
    ],
  }),
  getSupportedOrganizations: axiosResponseMocker({
    items: [
      { name: "Homes for All", initials: "HA", description: "Affordable housing" },
      {
        name: "Better Things",
        initials: "BT",
        description: "Community center and programming",
      },
    ],
  }),
  onboard: axiosResponseMocker({
    programs: [program()],
    memberships: [organizationMembership()],
    member: currentMember(),
    address: address(),
  }),
};

export const OnboardingIntro: Story = {
  render: () => {
    const props = useOnboardingProps(onboardingApiCalls);
    return <Onboarding {...props} />;
  },
};

export const OnboardingThemePage: Story = {
  render: () => {
    const props = useOnboardingProps(onboardingApiCalls, { step: 1 });
    return <OnboardingTheme {...props} />;
  },
};

export const OnboardingNamePage: Story = {
  render: () => {
    const props = useOnboardingProps(onboardingApiCalls, { step: 2 });
    return <OnboardingName {...props} />;
  },
};

export const OnboardingAddressPage: Story = {
  render: () => {
    const props = useOnboardingProps(onboardingApiCalls, { step: 3 });
    return <OnboardingAddress {...props} />;
  },
};

export const OnboardingEligibilityPage: Story = {
  render: () => {
    const props = useOnboardingProps(onboardingApiCalls, { step: 4 });
    return <OnboardingEligibility {...props} />;
  },
};

export const OnboardingOffersPage: Story = {
  render: () => {
    const props = useOnboardingProps(onboardingApiCalls, {
      step: 5,
      onboarded: {
        programs: [program()],
        memberships: [organizationMembership()],
        member: currentMember(),
        address: address(),
      },
    });
    return <OnboardingOffers {...props} />;
  },
};

export const OnboardingOffersNotOnboardedPage: Story = {
  render: () => {
    const props = useOnboardingProps(onboardingApiCalls, { step: 5 });
    return <OnboardingOffers {...props} />;
  },
};
