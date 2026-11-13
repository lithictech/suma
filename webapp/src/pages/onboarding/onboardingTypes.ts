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
  ) => Promise<AxiosResponse<{ items: SupportedOrganization[] }>>;
  onboard: (
    data: {
      name: string;
      address: OnboardingAddressType;
      organizationNames: string[];
    },
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
