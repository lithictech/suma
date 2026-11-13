import Home from "../pages/onboarding/Home.tsx";
import OneTimePassword from "../pages/onboarding/OneTimePassword.tsx";
import Start from "../pages/onboarding/Start.tsx";
import { axiosErrorMocker, axiosResponseMocker, currentMember } from "./fixtures.ts";
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
