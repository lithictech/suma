import { dayjs } from "../modules/dayConfig.ts";
import { RoutePath } from "../routing/RoutePath.ts";
import resolveRoutePath from "../routing/resolveRoutePath.ts";
import { AxiosResponse, InternalAxiosRequestConfig } from "axios";

let id = 1;

export function money(cents: number, currency: string = "USD") {
  return { cents, currency };
}

export function apiCollection<T>(
  items: T[],
  o: Omit<Partial<ApiCollection<T>>, "items"> = {}
): ApiCollection<T> {
  return {
    object: "fake",
    currentPage: 1,
    pageCount: 1,
    totalCount: items.length,
    hasMore: false,
    url: "/fake",
    items,
    ...o,
  };
}

export function currentMember(o: Partial<CurrentMember> = {}): CurrentMember {
  return {
    id: id++,
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
    chargeableCashBalance: null,
    finishedSurveyTopics: [],
    registrationLink: null,
    ...o,
  };
}

export function vendorService(o: Partial<VendorService> = {}): VendorService {
  return {
    id: id++,
    name: "Bikeshare",
    slug: "bikeshare",
    vendorName: "Bikeshare Operator",
    vendorSlug: "bikeop",
    ...o,
  };
}

export function rate(o: Partial<Rate> = {}): Rate {
  return {
    id: id++,
    surcharge: money(100),
    unitAmount: money(20),
    name: "demo",
    undiscountedRate: null,
    ...o,
  };
}

export function mobilityTrip(o: Partial<MobilityTrip> = {}): MobilityTrip {
  return {
    id: id++,
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
      undiscountedCost: money(200),
      customerCost: money(200),
      savings: money(200),
      lineItems: [{ amount: money(100), memo: "Unlock" }],
    },
    minutes: 20,
    image: null,
    ...o,
  };
}

export function paymentInstitution(o: Partial<Institution> = {}): Institution {
  return {
    name: "Visa",
    color: "#1A1F71",
    logoSrc:
      "data:image/png;base64,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",
    ...o,
  };
}

export function paymentInstrument(o: Partial<PaymentInstrument> = {}): PaymentInstrument {
  const pmid = id++;
  return {
    id: pmid,
    createdAt: "2024-09-27T19:03:31.998+00:00",
    paymentInstrumentId: pmid,
    paymentMethodType: "card",
    usableForFunding: true,
    status: "ok",
    expiresAt: "2027-03-01T00:00:00.000Z",
    name: "Visa x-6438",
    last4: "6438",
    key: "" + pmid,
    institution: paymentInstitution(),
    ...o,
  };
}

export function bankAccount(o: Partial<PaymentInstrument> = {}): PaymentInstrument {
  const o2: Partial<PaymentInstrument> = {
    paymentMethodType: "bank_account",
    expiresAt: null,
    institution: paymentInstitution({ logoSrc: "" }),
    ...o,
  };
  return paymentInstrument(o2);
}

export function axiosResponse<T>(
  data: T,
  overrides: Partial<AxiosResponse<T>> = {}
): AxiosResponse<T> {
  return {
    data,
    status: 200,
    statusText: "OK",
    headers: {},
    config: {} as InternalAxiosRequestConfig,
    ...overrides,
  };
}

export function axiosResponseMocker<T>(data: T): (arg: any) => Promise<AxiosResponse<T>> {
  return () => Promise.resolve(axiosResponse<T>(data));
}

export function fakeNavigate(p: RoutePath): void {
  console.log("navigating toL:", resolveRoutePath(p));
}

export function ledger(o: Partial<Ledger> = {}): Ledger {
  const nextId = id++;
  return {
    id: nextId,
    name: `Ledger ${nextId}`,
    contributionText: `Contribs ${nextId}`,
    balance: money(0),
    ...o,
  };
}
export function ledgersOverview(o: Partial<LedgersView> = {}): LedgersView {
  return {
    totalBalance: money(0),
    lifetimeSavings: money(12300),
    ledgers: [ledger({ name: "Cash" })],
    recentLines: [],
    ...o,
  };
}

export function ledgerLine(o: Partial<LedgerLine> = {}): LedgerLine {
  const nid = id++;
  return {
    id: nid,
    opaqueId: `opaque-${nid}`,
    at: dayjs().toISOString(),
    memo: `Memo for ${nid}`,
    amount: money(150),
    usageDetails: [
      {
        code: "misc",
        args: { discount_amount: money(225), service_name: "Misc Service" },
      },
    ],
    ...o,
  };
}

export function ledgerLineTrip(): LedgerLine {
  return ledgerLine({
    usageDetails: [
      {
        code: "mobility_trip",
        args: { discount_amount: money(225), service_name: "Suma Bikes" },
      },
    ],
  });
}

export function ledgerLineOrder(): LedgerLine {
  return ledgerLine({
    usageDetails: [
      {
        code: "commerce_order",
        args: { discount_amount: money(225), service_name: "Suma Food" },
      },
    ],
  });
}
