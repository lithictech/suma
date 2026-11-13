import { AxiosRequestConfig, AxiosResponse } from "axios";
import React from "react";

export interface OnboardingApiCalls {
  getSupportedGeographies: (
    data?: Record<string, any>,
    config?: AxiosRequestConfig
  ) => Promise<AxiosResponse<SupportedGeographies>>;
  getSupportedOrganizations: (
    data?: Record<string, any>,
    config?: AxiosRequestConfig
  ) => Promise<AxiosResponse<UnboundedApiCollection<SupportedOrganization>>>;
  onboard: (
    data?: Record<string, any>,
    config?: AxiosRequestConfig
  ) => Promise<AxiosResponse<Onboarded>>;
}

export interface OnboardingAddressType {
  address1: string;
  address2: string;
  city: string;
  stateOrProvince: string;
  postalCode: string;
}

export interface OnboardingState {
  step: number;
  totalSteps: number;
  address: OnboardingAddressType;
  name: string;
  organizationNames: string[];
  onboarded?: Onboarded;
}

type SetOnboardingStateField = <K extends keyof OnboardingState>(
  key: K,
  value: OnboardingState[K]
) => void;

export interface OnboardingProps {
  apiCalls: OnboardingApiCalls;
  onboardingState: OnboardingState;
  setOnboardingState: React.Dispatch<OnboardingState>;
  setOnboardingField: SetOnboardingStateField;
  stepForward: () => void;
  stepBackward: () => void;
}

export function useOnboardingProps(
  apiCalls: OnboardingApiCalls,
  initialState: Partial<OnboardingState> = {}
) {
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
    ...initialState,
  });
  const props: OnboardingProps = React.useMemo(
    () => ({
      apiCalls,
      onboardingState: state,
      setOnboardingState: setState,
      setOnboardingField: (f: string, v: any) =>
        setState((prev) => ({ ...prev, [f]: v })),
      stepForward: () => setState((prev) => ({ ...prev, step: prev.step + 1 })),
      stepBackward: () => setState((prev) => ({ ...prev, step: prev.step - 1 })),
    }),
    [apiCalls, state]
  );
  return props;
}
