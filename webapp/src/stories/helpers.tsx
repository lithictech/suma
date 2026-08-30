import { dayjs } from "../modules/dayConfig.ts";
import Stack from "../ui/Stack.tsx";
import React from "react";

export function DemoStack({
  row,
  gap = 3,
  children,
}: {
  row?: boolean;
  gap?: number;
  children: React.ReactNode;
}) {
  const direction = row ? "horizontal" : "vertical";
  return (
    <Stack direction={direction} gap={gap} style={{ maxWidth: 700 }}>
      {children}
    </Stack>
  );
}

export function currentMember(): CurrentMember {
  return {
    id: 1,
    createdAt: dayjs().toISOString(),
    email: "member@mysuma.org",
    name: "Ricky S",
    phone: "(555) 123-4567",
    onboarded: true,
    roleAccess: {},
    unclaimedOrdersCount: 0,
    ongoingTrip: null,
    readOnlyMode: false,
    readOnlyReason: "",
    paymentInstruments: [],
    adminMember: null,
    showPrivateAccounts: true,
    preferences: { subscriptions: [] },
    hasOrderHistory: false,
    chargeableCashBalance: { cents: 0, currency: "USD" },
    finishedSurveyTopics: [],
    registrationLink: null,
  };
}
