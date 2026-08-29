// Auto-generated typedefs from Grape::Entity
// Generated: 2026-08-18 10:43:02
// Entities: Money, Suma::API::AnonProxy::AnonProxyVendorAccountEntity, Suma::API::AnonProxy::AnonProxyVendorAccountPollResultEntity, Suma::API::AnonProxy::AnonProxyVendorAccountUIStateEntity, Suma::API::Auth::AuthFlowMemberEntity, Suma::API::Commerce::BaseOfferingProductEntity, Suma::API::Commerce::CartEntity, Suma::API::Commerce::CartItemEntity, Suma::API::Commerce::ChargeContributionEntity, Suma::API::Commerce::CheckoutConfirmationEntity, Suma::API::Commerce::CheckoutConfirmationItemEntity, Suma::API::Commerce::CheckoutConfirmationProductEntity, Suma::API::Commerce::CheckoutEntity, Suma::API::Commerce::CheckoutItemEntity, Suma::API::Commerce::CheckoutProductEntity, Suma::API::Commerce::DetailedOrderHistoryEntity, Suma::API::Commerce::FulfillmentOptionAddressEntity, Suma::API::Commerce::FulfillmentOptionEntity, Suma::API::Commerce::OfferingEntity, Suma::API::Commerce::OfferingWithContextEntity, Suma::API::Commerce::OrderHistoryCollection, Suma::API::Commerce::OrderHistoryFundingTransactionEntity, Suma::API::Commerce::OrderHistoryItemEntity, Suma::API::Commerce::PricedOfferingProductEntity, Suma::API::Commerce::SimpleOrderHistoryEntity, Suma::API::Commerce::UnclaimedOrderCollection, Suma::API::Commerce::VendorEntity, Suma::API::Entities::AddressEntity, Suma::API::Entities::BaseEntity, Suma::API::Entities::CurrencyEntity, Suma::API::Entities::CurrentMemberEntity, Suma::API::Entities::ImageEntity, Suma::API::Entities::InstitutionEntity, Suma::API::Entities::LedgerEntity, Suma::API::Entities::LedgerLineEntity, Suma::API::Entities::LedgerLineUsageDetailsEntity, Suma::API::Entities::LegalEntityEntity, Suma::API::Entities::LocaleEntity, Suma::API::Entities::MemberPreferencesEntity, Suma::API::Entities::MobilityChargeEntity, Suma::API::Entities::MobilityChargeLineItemEntity, Suma::API::Entities::MobilityTripEntity, Suma::API::Entities::MobilityTripParsedAddressEntity, Suma::API::Entities::MoneyEntity, Suma::API::Entities::PaymentInstrumentEntity, Suma::API::Entities::PreferencesSubscriptionEntity, Suma::API::Entities::RegistrationLinkEntity, Suma::API::Entities::VendorServiceEntity, Suma::API::Images::UploadedFileEntity, Suma::API::Ledgers::LedgerLinesEntity, Suma::API::Ledgers::LedgersViewEntity, Suma::API::Me::DashboardAlertEntity, Suma::API::Me::DashboardEntity, Suma::API::Me::MembershipEntity, Suma::API::Me::OnboardedEntity, Suma::API::Me::ProgramEntity, Suma::API::Meta::GeolocateIPEntity, Suma::API::Meta::SupportedCountryEntity, Suma::API::Meta::SupportedGeographiesEntity, Suma::API::Meta::SupportedOrganizationEntity, Suma::API::Meta::SupportedProvinceEntity, Suma::API::Mobility::MobilityDetailedVehicleEntity, Suma::API::Mobility::MobilityMapEntity, Suma::API::Mobility::MobilityMapFeaturesEntity, Suma::API::Mobility::MobilityMapProviderEntity, Suma::API::Mobility::MobilityMapRestrictionBoundsEntity, Suma::API::Mobility::MobilityMapRestrictionEntity, Suma::API::Mobility::MobilityMapVehicleEntity, Suma::API::Mobility::MobilityTripCollectionEntity, Suma::API::Mobility::MobilityTripCollectionWeekEntity, Suma::API::Mobility::RateEntity, Suma::API::Mobility::SimpleRateEntity, Suma::API::PaymentInstruments::MutationPaymentInstrumentEntity, Suma::API::Payments::FundingTransactionEntity, Suma::API::Preferences::PublicPrefsEntity, Suma::API::Preferences::PublicPrefsMemberEntity

declare global {
  /** Auto-generated from Money */
  interface Money {
    cents: number;
    currency: string;
  }

  /** Auto-generated from Suma::API::AnonProxy::AnonProxyVendorAccountEntity */
  interface AnonProxyVendorAccount {
    id: number;
    magicLink: string;
    vendorName: string;
    vendorSlug: string;
    vendorImage: Image;
    uiStateV1: AnonProxyVendorAccountUIState;
  }

  /** Auto-generated from Suma::API::AnonProxy::AnonProxyVendorAccountPollResultEntity */
  interface AnonProxyVendorAccountPollResult {
    foundChange: boolean;
    successInstructions: string;
    vendorAccount: AnonProxyVendorAccount;
  }

  /** Auto-generated from Suma::API::AnonProxy::AnonProxyVendorAccountUIStateEntity */
  interface AnonProxyVendorAccountUIState {
    indexCardMode: string;
    needsLinking: boolean;
    requiresPaymentMethod: boolean;
    hasPaymentMethod: boolean;
    balancePayoffNeeded: boolean;
    showPaymentStep: boolean;
    termStepIndex: number;
    linkStepIndex: number;
    descriptionText: string;
    termsText: string;
    helpText: string;
  }

  /** Auto-generated from Suma::API::Auth::AuthFlowMemberEntity */
  interface AuthFlowMember {
    requiresTermsAgreement: boolean;
  }

  /** Auto-generated from Suma::API::Commerce::BaseOfferingProductEntity */
  interface BaseOfferingProduct {
    name: string;
    description: string;
    offeringId: number;
    productId: number;
    vendor: Vendor;
    images: Image[];
  }

  /** Auto-generated from Suma::API::Commerce::CartEntity */
  interface Cart {
    cartHash: string;
    items: CartItem[];
    customerCost: Money;
    noncashLedgerContributionAmount: Money;
    cashCost: Money;
    cartFull: boolean;
  }

  /** Auto-generated from Suma::API::Commerce::CartItemEntity */
  interface CartItem {
    quantity: number;
    productId: number;
  }

  /** Auto-generated from Suma::API::Commerce::ChargeContributionEntity */
  interface ChargeContribution {
    amount: Money;
    name: string;
  }

  /** Auto-generated from Suma::API::Commerce::CheckoutConfirmationEntity */
  interface CheckoutConfirmation {
    id: number;
    items: CheckoutConfirmationItem[];
    offering: Offering;
    fulfillmentOption: FulfillmentOption;
  }

  /** Auto-generated from Suma::API::Commerce::CheckoutConfirmationItemEntity */
  interface CheckoutConfirmationItem {
    product: CheckoutConfirmationProduct;
    quantity: number;
  }

  /** Auto-generated from Suma::API::Commerce::CheckoutConfirmationProductEntity */
  interface CheckoutConfirmationProduct {
    name: string;
    description: string;
    offeringId: number;
    productId: number;
    vendor: Vendor;
    images: Image[];
  }

  /** Auto-generated from Suma::API::Commerce::CheckoutEntity */
  interface Checkout {
    id: number;
    items: CheckoutItem[];
    offering: Offering;
    fulfillmentOptionId: number;
    availableFulfillmentOptions: FulfillmentOption[];
    paymentInstrument: PaymentInstrument;
    availablePaymentInstruments: PaymentInstrument[];
    unavailablePaymentInstruments: PaymentInstrument[];
    customerCost: Money;
    undiscountedCost: Money;
    savings: Money;
    handling: Money;
    taxableCost: Money;
    tax: Money;
    total: Money;
    chargeableTotal: Money;
    requiresPaymentInstrument: boolean;
    checkoutProhibitedReason: string;
    existingFundsAvailable: ChargeContribution[];
  }

  /** Auto-generated from Suma::API::Commerce::CheckoutItemEntity */
  interface CheckoutItem {
    product: CheckoutProduct;
    quantity: number;
  }

  /** Auto-generated from Suma::API::Commerce::CheckoutProductEntity */
  interface CheckoutProduct {
    name: string;
    description: string;
    offeringId: number;
    productId: number;
    vendor: Vendor;
    images: Image[];
    listable: boolean;
    maxQuantity: number;
    outOfStock: boolean;
    outOfStockReason: string;
    outOfStockReasonText: string;
    displayableNoncashLedgerContributionAmount: Money;
    displayableCashPrice: Money;
    isDiscounted: boolean;
    customerPrice: Money;
    undiscountedPrice: Money;
    discountAmount: Money;
  }

  /** Auto-generated from Suma::API::Commerce::DetailedOrderHistoryEntity */
  interface DetailedOrderHistory {
    id: number;
    serial: string;
    createdAt: string;
    fulfilledAt: string;
    total: Money;
    image: Image;
    availableForPickupAt: string;
    items: OrderHistoryItem[];
    offeringId: number;
    offeringDescription: string;
    fulfillmentConfirmation: string;
    fulfillmentOption: FulfillmentOption;
    fulfillmentOptionsForEditing: FulfillmentOption[];
    fulfillmentOptionEditable: boolean;
    orderStatus: string;
    canClaim: boolean;
    customerCost: Money;
    undiscountedCost: Money;
    savings: Money;
    handling: Money;
    taxableCost: Money;
    tax: Money;
    fundingTransactions: OrderHistoryFundingTransaction[];
  }

  /** Auto-generated from Suma::API::Commerce::FulfillmentOptionAddressEntity */
  interface FulfillmentOptionAddress {
    oneLineAddress: string;
  }

  /** Auto-generated from Suma::API::Commerce::FulfillmentOptionEntity */
  interface FulfillmentOption {
    id: number;
    description: string;
    address: FulfillmentOptionAddress;
  }

  /** Auto-generated from Suma::API::Commerce::OfferingEntity */
  interface Offering {
    id: number;
    description: string;
    fulfillmentPrompt: string;
    fulfillmentConfirmation: string;
    fulfillmentInstructions: string;
    closesAt: string;
    image: Image;
    appLink: string;
  }

  /** Auto-generated from Suma::API::Commerce::OfferingWithContextEntity */
  interface OfferingWithContext {
    offering: Offering;
    items: PricedOfferingProduct[];
    vendors: Vendor[];
    cart: Cart;
  }

  /** Auto-generated from Suma::API::Commerce::OrderHistoryCollection */
  interface OrderHistoryCollection {
    object: string;
    currentPage: number;
    pageCount: number;
    totalCount: number;
    hasMore: boolean;
    url: string;
    items: SimpleOrderHistory[];
    detailedOrders: DetailedOrderHistory[];
  }

  /** Auto-generated from Suma::API::Commerce::OrderHistoryFundingTransactionEntity */
  interface OrderHistoryFundingTransaction {
    amount: Money;
    label: string;
  }

  /** Auto-generated from Suma::API::Commerce::OrderHistoryItemEntity */
  interface OrderHistoryItem {
    quantity: number;
    name: string;
    description: string;
    image: Image;
    customerPrice: Money;
  }

  /** Auto-generated from Suma::API::Commerce::PricedOfferingProductEntity */
  interface PricedOfferingProduct {
    name: string;
    description: string;
    offeringId: number;
    productId: number;
    vendor: Vendor;
    images: Image[];
    listable: boolean;
    maxQuantity: number;
    outOfStock: boolean;
    outOfStockReason: string;
    outOfStockReasonText: string;
    displayableNoncashLedgerContributionAmount: Money;
    displayableCashPrice: Money;
    isDiscounted: boolean;
    customerPrice: Money;
    undiscountedPrice: Money;
    discountAmount: Money;
  }

  /** Auto-generated from Suma::API::Commerce::SimpleOrderHistoryEntity */
  interface SimpleOrderHistory {
    id: number;
    serial: string;
    createdAt: string;
    fulfilledAt: string;
    total: Money;
    image: Image;
    availableForPickupAt: string;
  }

  /** Auto-generated from Suma::API::Commerce::UnclaimedOrderCollection */
  interface UnclaimedOrderCollection {
    object: string;
    currentPage: number;
    pageCount: number;
    totalCount: number;
    hasMore: boolean;
    url: string;
    items: DetailedOrderHistory[];
  }

  /** Auto-generated from Suma::API::Commerce::VendorEntity */
  interface Vendor {
    id: number;
    name: string;
  }

  /** Auto-generated from Suma::API::Entities::AddressEntity */
  interface Address {
    address1: string;
    address2: string;
    city: string;
    stateOrProvince: string;
    postalCode: string;
    country: string;
    lat: number;
    lng: number;
    oneLineAddress: string;
  }

  /** Auto-generated from Suma::API::Entities::BaseEntity */
  interface Base {}

  /** Auto-generated from Suma::API::Entities::CurrencyEntity */
  interface Currency {
    symbol: string;
    code: string;
    fundingMinimumCents: number;
    fundingMaximumCents: number;
    fundingStepCents: number;
    centsInDollar: number;
    paymentMethodTypes: string[];
  }

  /** Auto-generated from Suma::API::Entities::CurrentMemberEntity */
  interface CurrentMember {
    id: number;
    createdAt: string;
    email: string;
    name: string;
    phone: string;
    onboarded: boolean;
    roleAccess: RoleAccessType;
    unclaimedOrdersCount: number;
    ongoingTrip: MobilityTrip;
    readOnlyMode: boolean;
    readOnlyReason: string;
    paymentInstruments: PaymentInstrument[];
    adminMember: CurrentMember;
    showPrivateAccounts: boolean;
    preferences: MemberPreferences;
    hasOrderHistory: boolean;
    chargeableCashBalance: Money;
    finishedSurveyTopics: string[];
    registrationLink: RegistrationLink;
  }

  /** Auto-generated from Suma::API::Entities::ImageEntity */
  interface Image {
    caption: string;
    url: string;
  }

  /** Auto-generated from Suma::API::Entities::InstitutionEntity */
  interface Institution {
    name: string;
    logoSrc: string;
    color: string;
  }

  /** Auto-generated from Suma::API::Entities::LedgerEntity */
  interface Ledger {
    id: number;
    name: string;
    contributionText: string;
    balance: Money;
  }

  /** Auto-generated from Suma::API::Entities::LedgerLineEntity */
  interface LedgerLine {
    id: number;
    opaqueId: number;
    at: string;
    memo: string;
    amount: Money;
    usageDetails: LedgerLineUsageDetails[];
  }

  /** Auto-generated from Suma::API::Entities::LedgerLineUsageDetailsEntity */
  interface LedgerLineUsageDetails {
    code: string;
    args: RecordString;
  }

  /** Auto-generated from Suma::API::Entities::LegalEntityEntity */
  interface LegalEntity {
    id: number;
    name: string;
    address: Address;
  }

  /** Auto-generated from Suma::API::Entities::LocaleEntity */
  interface Locale {
    code: string;
    language: string;
    native: string;
  }

  /** Auto-generated from Suma::API::Entities::MemberPreferencesEntity */
  interface MemberPreferences {
    subscriptions: PreferencesSubscription[];
  }

  /** Auto-generated from Suma::API::Entities::MobilityChargeEntity */
  interface MobilityCharge {
    undiscountedCost: Money;
    customerCost: Money;
    savings: Money;
    lineItems: MobilityChargeLineItem[];
  }

  /** Auto-generated from Suma::API::Entities::MobilityChargeLineItemEntity */
  interface MobilityChargeLineItem {
    amount: Money;
    memo: string;
  }

  /** Auto-generated from Suma::API::Entities::MobilityTripEntity */
  interface MobilityTrip {
    id: number;
    vehicleId: string;
    vehicleType: string;
    provider: VendorService;
    beginLat: number;
    beginLng: number;
    beginAddress: MobilityTripParsedAddress;
    beganAt: string;
    endLat: number;
    endLng: number;
    endAddress: MobilityTripParsedAddress;
    endedAt: string;
    ongoing: boolean;
    charge: MobilityCharge;
    minutes: number;
    image: Image;
  }

  /** Auto-generated from Suma::API::Entities::MobilityTripParsedAddressEntity */
  interface MobilityTripParsedAddress {
    part1: string;
    part2: string;
  }

  /** Auto-generated from Suma::API::Entities::MoneyEntity */
  interface Money {
    cents: number;
    currency: string;
  }

  /** Auto-generated from Suma::API::Entities::PaymentInstrumentEntity */
  interface PaymentInstrument {
    id: number;
    createdAt: string;
    paymentInstrumentId: number;
    paymentMethodType: string;
    usableForFunding: boolean;
    status: string;
    expiresAt: string;
    institution: Institution;
    name: string;
    last4: string;
    key: string;
  }

  /** Auto-generated from Suma::API::Entities::PreferencesSubscriptionEntity */
  interface PreferencesSubscription {
    key: string;
    optedIn: boolean;
    editableState: string;
  }

  /** Auto-generated from Suma::API::Entities::RegistrationLinkEntity */
  interface RegistrationLink {
    organizationName: string;
    intro: string;
  }

  /** Auto-generated from Suma::API::Entities::VendorServiceEntity */
  interface VendorService {
    id: number;
    name: string;
    slug: string;
    vendorName: string;
    vendorSlug: string;
  }

  /** Auto-generated from Suma::API::Images::UploadedFileEntity */
  interface UploadedFile {
    opaqueId: number;
    contentType: string;
    contentLength: number;
    absoluteUrl: string;
  }

  /** Auto-generated from Suma::API::Ledgers::LedgerLinesEntity */
  interface LedgerLines {
    object: string;
    currentPage: number;
    pageCount: number;
    totalCount: number;
    hasMore: boolean;
    url: string;
    items: LedgerLine[];
    ledgerId: number;
  }

  /** Auto-generated from Suma::API::Ledgers::LedgersViewEntity */
  interface LedgersView {
    totalBalance: Money;
    lifetimeSavings: Money;
    ledgers: Ledger[];
    recentLines: LedgerLine[];
  }

  /** Auto-generated from Suma::API::Me::DashboardAlertEntity */
  interface DashboardAlert {
    localizationKey: string;
    localizationParams: RecordString;
    variant: string;
  }

  /** Auto-generated from Suma::API::Me::DashboardEntity */
  interface Dashboard {
    cashBalance: Money;
    programs: Program[];
    alerts: DashboardAlert[];
  }

  /** Auto-generated from Suma::API::Me::MembershipEntity */
  interface Membership {
    organizationName: string;
    status: string;
  }

  /** Auto-generated from Suma::API::Me::OnboardedEntity */
  interface Onboarded {
    programs: Program[];
    memberships: Membership[];
    member: CurrentMember;
    address: Address;
  }

  /** Auto-generated from Suma::API::Me::ProgramEntity */
  interface Program {
    name: string;
    description: string;
    image: Image;
    periodBegin: string;
    periodEnd: string;
    appLink: string;
    appLinkText: string;
  }

  /** Auto-generated from Suma::API::Meta::GeolocateIPEntity */
  interface GeolocateIP {
    lat: number;
    lng: number;
  }

  /** Auto-generated from Suma::API::Meta::SupportedCountryEntity */
  interface SupportedCountry {
    label: string;
    value: string;
  }

  /** Auto-generated from Suma::API::Meta::SupportedGeographiesEntity */
  interface SupportedGeographies {
    countries: SupportedCountry[];
    provinces: SupportedProvince[];
  }

  /** Auto-generated from Suma::API::Meta::SupportedOrganizationEntity */
  interface SupportedOrganization {
    name: string;
  }

  /** Auto-generated from Suma::API::Meta::SupportedProvinceEntity */
  interface SupportedProvince {
    label: string;
    value: string;
    countryIdx: number;
  }

  /** Auto-generated from Suma::API::Mobility::MobilityDetailedVehicleEntity */
  interface MobilityDetailedVehicle {
    precision: number;
    vendorService: VendorService;
    vehicleId: string;
    loc: number[];
    rate: Rate;
    subsidyMatchPercentage: number;
    deeplink: string;
    gotoPrivateAccount: string;
    usageProhibitedReason: string;
  }

  /** Auto-generated from Suma::API::Mobility::MobilityMapEntity */
  interface MobilityMap {
    precision: number;
    refresh: number;
    providers: MobilityMapProvider[];
    escooter: MobilityMapVehicle[];
    ebike: MobilityMapVehicle[];
  }

  /** Auto-generated from Suma::API::Mobility::MobilityMapFeaturesEntity */
  interface MobilityMapFeatures {
    restrictions: MobilityMapRestriction[];
  }

  /** Auto-generated from Suma::API::Mobility::MobilityMapProviderEntity */
  interface MobilityMapProvider {
    id: number;
    name: string;
    slug: string;
    vendorName: string;
    vendorSlug: string;
    rate: SimpleRate;
    usageProhibitedReason: string;
  }

  /** Auto-generated from Suma::API::Mobility::MobilityMapRestrictionBoundsEntity */
  interface MobilityMapRestrictionBounds {
    ne: GeoLatLng;
    sw: GeoLatLng;
  }

  /** Auto-generated from Suma::API::Mobility::MobilityMapRestrictionEntity */
  interface MobilityMapRestriction {
    restriction: string;
    multipolygon: GeoMultiPolygon;
    bounds: MobilityMapRestrictionBounds;
  }

  /** Auto-generated from Suma::API::Mobility::MobilityMapVehicleEntity */
  interface MobilityMapVehicle {
    c: number[];
    p: number;
    d: string;
    o: number[];
  }

  /** Auto-generated from Suma::API::Mobility::MobilityTripCollectionEntity */
  interface MobilityTripCollection {
    object: string;
    currentPage: number;
    pageCount: number;
    totalCount: number;
    hasMore: boolean;
    url: string;
    items: MobilityTrip[];
    ongoing: MobilityTrip;
    weeks: MobilityTripCollectionWeek[];
  }

  /** Auto-generated from Suma::API::Mobility::MobilityTripCollectionWeekEntity */
  interface MobilityTripCollectionWeek {
    beginAt: string;
    endAt: string;
    beginIndex: number;
    endIndex: number;
  }

  /** Auto-generated from Suma::API::Mobility::RateEntity */
  interface Rate {
    id: number;
    surcharge: Money;
    unitAmount: Money;
    name: string;
    undiscountedRate: SimpleRate;
  }

  /** Auto-generated from Suma::API::Mobility::SimpleRateEntity */
  interface SimpleRate {
    id: number;
    surcharge: Money;
    unitAmount: Money;
  }

  /** Auto-generated from Suma::API::PaymentInstruments::MutationPaymentInstrumentEntity */
  interface MutationPaymentInstrument {
    id: number;
    createdAt: string;
    paymentInstrumentId: number;
    paymentMethodType: string;
    usableForFunding: boolean;
    status: string;
    expiresAt: string;
    institution: Institution;
    name: string;
    last4: string;
    key: string;
    allPaymentInstruments: PaymentInstrument[];
  }

  /** Auto-generated from Suma::API::Payments::FundingTransactionEntity */
  interface FundingTransaction {
    id: number;
    createdAt: string;
    status: string;
    amount: Money;
    memo: string;
  }

  /** Auto-generated from Suma::API::Preferences::PublicPrefsEntity */
  interface PublicPrefs {
    subscriptions: PreferencesSubscription[];
  }

  /** Auto-generated from Suma::API::Preferences::PublicPrefsMemberEntity */
  interface PublicPrefsMember {
    email: string;
    name: string;
    phone: string;
    preferences: PublicPrefs;
  }

  type RoleAccessType = Record<string, string[]>;
  type RecordString = Record<string, unknown>;
  type GeoLatLng = [number, number];
  type GeoMultiPolygon = GeoPolygon[];
  type GeoPolygon = GeoLinearRing[];
  type GeoLinearRing = GeoLatLng[];
}

export {};
