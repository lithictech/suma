import React from "react";

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
  onboardingState: OnboardingState;
  setOnboardingState: React.Dispatch<OnboardingState>;
  setOnboardingField: SetOnboardingStateField;
  stepForward: () => void;
  stepBackward: () => void;
}
