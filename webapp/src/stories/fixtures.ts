import { dayjs } from "../modules/dayConfig.ts";

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

export function vendorService(): VendorService {
  return {
    id: 2,
    name: "Bikeshare",
    slug: "bikeshare",
    vendorName: "Bikeshare Operator",
    vendorSlug: "bikeop",
  };
}

export function rate(): Rate {
  return {
    id: 50,
    surcharge: { cents: 100, currency: "USD" },
    unitAmount: { cents: 20, currency: "USD" },
    name: "demo",
    undiscountedRate: null,
  };
}

export function mobilityTrip(): MobilityTrip {
  return {
    id: 1,
    vehicleId: "vehicle5",
    vehicleType: "ebike",
    provider: vendorService(),
    beginLat: 0,
    beginLng: 1,
    beginAddress: { part1: "123 Main St", part2: "Portland, OR" },
    beganAt: "2020-01-01T12:00:00Z",
    endLat: 10,
    endLng: 11,
    endAddress: { part1: "123 Main St", part2: "Portland, OR" },
    endedAt: "2020-01-01T12:00:00Z",
    ongoing: false,
    charge: {
      undiscountedCost: { cents: 200, currency: "USD" },
      customerCost: { cents: 200, currency: "USD" },
      savings: { cents: 200, currency: "USD" },
      lineItems: [{ amount: { cents: 100, currency: "USD" }, memo: "Unlock" }],
    },
    minutes: 20,
    image: null,
  };
}
