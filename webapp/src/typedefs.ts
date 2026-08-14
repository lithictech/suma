// Auto-generated typedefs from Grape::Entity
// Generated: 2026-08-11 15:39:14
// Entities: Money, Suma::API::AnonProxy::AnonProxyVendorAccountEntity, Suma::API::AnonProxy::AnonProxyVendorAccountPollResultEntity, Suma::API::AnonProxy::AnonProxyVendorAccountUIStateEntity, Suma::API::Auth::AuthFlowMemberEntity, Suma::API::Commerce::BaseOfferingProductEntity, Suma::API::Commerce::CartEntity, Suma::API::Commerce::CartItemEntity, Suma::API::Commerce::ChargeContributionEntity, Suma::API::Commerce::CheckoutConfirmationEntity, Suma::API::Commerce::CheckoutConfirmationItemEntity, Suma::API::Commerce::CheckoutConfirmationProductEntity, Suma::API::Commerce::CheckoutEntity, Suma::API::Commerce::CheckoutItemEntity, Suma::API::Commerce::CheckoutProductEntity, Suma::API::Commerce::DetailedOrderHistoryEntity, Suma::API::Commerce::FulfillmentOptionAddressEntity, Suma::API::Commerce::FulfillmentOptionEntity, Suma::API::Commerce::OfferingEntity, Suma::API::Commerce::OfferingWithContextEntity, Suma::API::Commerce::OrderHistoryCollection, Suma::API::Commerce::OrderHistoryFundingTransactionEntity, Suma::API::Commerce::OrderHistoryItemEntity, Suma::API::Commerce::PricedOfferingProductEntity, Suma::API::Commerce::SimpleOrderHistoryEntity, Suma::API::Commerce::UnclaimedOrderCollection, Suma::API::Commerce::VendorEntity, Suma::API::Entities::BaseEntity, Suma::API::Entities::CurrencyEntity, Suma::API::Entities::CurrentMemberEntity, Suma::API::Entities::ImageEntity, Suma::API::Entities::LedgerEntity, Suma::API::Entities::LedgerLineEntity, Suma::API::Entities::LedgerLineUsageDetailsEntity, Suma::API::Entities::LocaleEntity, Suma::API::Entities::MemberPreferencesEntity, Suma::API::Entities::MobilityChargeEntity, Suma::API::Entities::MobilityChargeLineItemEntity, Suma::API::Entities::MobilityTripEntity, Suma::API::Entities::PaymentInstrumentEntity, Suma::API::Entities::PreferencesSubscriptionEntity, Suma::API::Entities::RegistrationLinkEntity, Suma::API::Entities::VendorServiceEntity, Suma::API::Images::UploadedFileEntity, Suma::API::Ledgers::LedgerLinesEntity, Suma::API::Ledgers::LedgersViewEntity, Suma::API::Me::DashboardAlertEntity, Suma::API::Me::DashboardEntity, Suma::API::Me::ProgramEntity, Suma::API::Mobility::MobilityDetailedVehicleEntity, Suma::API::Mobility::MobilityMapEntity, Suma::API::Mobility::MobilityMapFeaturesEntity, Suma::API::Mobility::MobilityMapProviderEntity, Suma::API::Mobility::MobilityMapRestrictionEntity, Suma::API::Mobility::MobilityMapVehicleEntity, Suma::API::Mobility::MobilityTripCollectionEntity, Suma::API::Mobility::RateEntity, Suma::API::Mobility::SimpleRateEntity, Suma::API::PaymentInstruments::MutationPaymentInstrumentEntity, Suma::API::Payments::FundingTransactionEntity, Suma::API::Preferences::PublicPrefsEntity, Suma::API::Preferences::PublicPrefsMemberEntity
//
// NOTE: The generator (lib/suma/service/typewriter.rb) emits the referenced entity's bare
// type for any `expose :x, with: SomeEntity` field, even when `x` is actually a collection
// (Grape::Entity detects array-ness at serialization time, which the generator can't see
// statically). The array annotations below (marked "manually corrected") were hand-fixed
// by cross-referencing the `with:`/`using:` exposures in lib/suma/api/*.rb against actual
// array usage in the webapp. Re-running the generator will clobber these fixes; the real
// fix belongs in typewriter.rb (e.g. tracking `is_array` on the exposure).

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
    foundChange: any;
    successInstructions: any;
    vendorAccount: AnonProxyVendorAccount;
  }

  /** Auto-generated from Suma::API::AnonProxy::AnonProxyVendorAccountUIStateEntity */
  interface AnonProxyVendorAccountUIState {
    indexCardMode: any;
    needsLinking: boolean;
    requiresPaymentMethod: any;
    hasPaymentMethod: any;
    balancePayoffNeeded: any;
    showPaymentStep: any;
    termStepIndex: any;
    linkStepIndex: any;
    descriptionText: any;
    termsText: any;
    helpText: any;
  }

  /** Auto-generated from Suma::API::Auth::AuthFlowMemberEntity */
  interface AuthFlowMember {
    requiresTermsAgreement: any;
  }

  /** Auto-generated from Suma::API::Commerce::BaseOfferingProductEntity */
  interface BaseOfferingProduct {
    name: string;
    description: string;
    offeringId: number;
    productId: number;
    vendor: Vendor;
    /** manually corrected: array (with: ImageEntity) */
    images: Image[];
  }

  /** Auto-generated from Suma::API::Commerce::CartEntity */
  interface Cart {
    cartHash: any;
    /** manually corrected: array (with: CartItemEntity) */
    items: CartItem[];
    customerCost: Money;
    noncashLedgerContributionAmount: Money;
    cashCost: Money;
    cartFull: any;
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
    /** manually corrected: array (with: CheckoutConfirmationItemEntity) */
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
    /** manually corrected: array (with: ImageEntity) */
    images: Image[];
  }

  /** Auto-generated from Suma::API::Commerce::CheckoutEntity */
  interface Checkout {
    id: number;
    /** manually corrected: array (with: CheckoutItemEntity) */
    items: CheckoutItem[];
    offering: Offering;
    fulfillmentOptionId: number;
    /** manually corrected: array (with: FulfillmentOptionEntity) */
    availableFulfillmentOptions: FulfillmentOption[];
    paymentInstrument: PaymentInstrument;
    /** manually corrected: array (with: PaymentInstrumentEntity) */
    availablePaymentInstruments: PaymentInstrument[];
    /** manually corrected: array (with: PaymentInstrumentEntity) */
    unavailablePaymentInstruments: PaymentInstrument[];
    customerCost: Money;
    undiscountedCost: Money;
    savings: Money;
    handling: Money;
    taxableCost: Money;
    tax: Money;
    total: Money;
    chargeableTotal: Money;
    requiresPaymentInstrument: any;
    checkoutProhibitedReason: string;
    /** manually corrected: array (with: ChargeContributionEntity) */
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
    /** manually corrected: array (with: ImageEntity) */
    images: Image[];
    listable: any;
    maxQuantity: number;
    outOfStock: any;
    outOfStockReason: string;
    outOfStockReasonText: any;
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
    serial: any;
    createdAt: string;
    fulfilledAt: string;
    total: Money;
    image: Image;
    availableForPickupAt: string;
    /** manually corrected: array (with: OrderHistoryItemEntity) */
    items: OrderHistoryItem[];
    offeringId: number;
    offeringDescription: string;
    fulfillmentConfirmation: any;
    fulfillmentOption: FulfillmentOption;
    /** manually corrected: array (with: FulfillmentOptionEntity) */
    fulfillmentOptionsForEditing: FulfillmentOption[];
    fulfillmentOptionEditable: any;
    orderStatus: string;
    canClaim: boolean;
    customerCost: Money;
    undiscountedCost: Money;
    savings: Money;
    handling: Money;
    taxableCost: Money;
    tax: Money;
    /** manually corrected: array (with: OrderHistoryFundingTransactionEntity) */
    fundingTransactions: OrderHistoryFundingTransaction[];
  }

  /** Auto-generated from Suma::API::Commerce::FulfillmentOptionAddressEntity */
  interface FulfillmentOptionAddress {
    oneLineAddress: any;
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
    fulfillmentPrompt: any;
    fulfillmentConfirmation: any;
    fulfillmentInstructions: any;
    closesAt: string;
    image: Image;
    appLink: string;
  }

  /** Auto-generated from Suma::API::Commerce::OfferingWithContextEntity */
  interface OfferingWithContext {
    offering: Offering;
    /** manually corrected: array of PricedOfferingProduct (block-exposed, no entity reference to infer from) */
    items: PricedOfferingProduct[];
    /** manually corrected: array (with: VendorEntity) */
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
    /** manually corrected: array (with: SimpleOrderHistoryEntity) */
    items: SimpleOrderHistory[];
    /** manually corrected: array (with: DetailedOrderHistoryEntity) */
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
    /** manually corrected: array (with: ImageEntity) */
    images: Image[];
    listable: any;
    maxQuantity: number;
    outOfStock: any;
    outOfStockReason: string;
    outOfStockReasonText: any;
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
    serial: any;
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
    /** manually corrected: array (with: DetailedOrderHistoryEntity) */
    items: DetailedOrderHistory[];
  }

  /** Auto-generated from Suma::API::Commerce::VendorEntity */
  interface Vendor {
    id: number;
    name: string;
  }

  /** Auto-generated from Suma::API::Entities::BaseEntity */
  interface Base {}

  /** Auto-generated from Suma::API::Entities::CurrencyEntity */
  interface Currency {
    symbol: any;
    code: string;
    fundingMinimumCents: number;
    fundingMaximumCents: number;
    fundingStepCents: number;
    centsInDollar: any;
    paymentMethodTypes: any;
  }

  /** Auto-generated from Suma::API::Entities::CurrentMemberEntity */
  interface CurrentMember {
    id: number;
    createdAt: string;
    email: string;
    name: string;
    phone: string;
    onboarded: any;
    roleAccess: any;
    unclaimedOrdersCount: number;
    ongoingTrip: MobilityTrip;
    readOnlyMode: any;
    readOnlyReason: string;
    /** manually corrected: array (with: PaymentInstrumentEntity) */
    paymentInstruments: PaymentInstrument[];
    adminMember: CurrentMember;
    showPrivateAccounts: any;
    preferences: MemberPreferences;
    hasOrderHistory: any;
    chargeableCashBalance: Money;
    finishedSurveyTopics: any;
    registrationLink: RegistrationLink;
  }

  /** Auto-generated from Suma::API::Entities::ImageEntity */
  interface Image {
    caption: any;
    url: string;
  }

  /** Auto-generated from Suma::API::Entities::LedgerEntity */
  interface Ledger {
    id: number;
    name: string;
    contributionText: any;
    balance: Money;
  }

  /** Auto-generated from Suma::API::Entities::LedgerLineEntity */
  interface LedgerLine {
    id: number;
    opaqueId: number;
    at: string;
    memo: any;
    amount: Money;
    /** manually corrected: array (with: LedgerLineUsageDetailsEntity) */
    usageDetails: LedgerLineUsageDetails[];
  }

  /** Auto-generated from Suma::API::Entities::LedgerLineUsageDetailsEntity */
  interface LedgerLineUsageDetails {
    code: string;
    args: any;
  }

  /** Auto-generated from Suma::API::Entities::LocaleEntity */
  interface Locale {
    code: string;
    language: any;
    native: any;
  }

  /** Auto-generated from Suma::API::Entities::MemberPreferencesEntity */
  interface MemberPreferences {
    /** manually corrected: array (with: PreferencesSubscriptionEntity) */
    subscriptions: PreferencesSubscription[];
  }

  /** Auto-generated from Suma::API::Entities::MobilityChargeEntity */
  interface MobilityCharge {
    undiscountedCost: Money;
    customerCost: Money;
    savings: Money;
    /** manually corrected: array (with: MobilityChargeLineItemEntity) */
    lineItems: MobilityChargeLineItem[];
  }

  /** Auto-generated from Suma::API::Entities::MobilityChargeLineItemEntity */
  interface MobilityChargeLineItem {
    amount: Money;
    memo: any;
  }

  /** Auto-generated from Suma::API::Entities::MobilityTripEntity */
  interface MobilityTrip {
    id: number;
    vehicleId: number;
    vehicleType: string;
    provider: VendorService;
    beginLat: number;
    beginLng: number;
    beginAddress: any;
    beganAt: string;
    endLat: number;
    endLng: number;
    endAddress: any;
    endedAt: string;
    ongoing: any;
    charge: MobilityCharge;
    minutes: any;
    image: Image;
  }

  /** Auto-generated from Suma::API::Entities::PaymentInstrumentEntity */
  interface PaymentInstrument {
    id: number;
    createdAt: string;
    paymentInstrumentId: number;
    paymentMethodType: string;
    usableForFunding: any;
    status: string;
    expiresAt: string;
    institution: any;
    name: string;
    last4: string;
    key: string;
  }

  /** Auto-generated from Suma::API::Entities::PreferencesSubscriptionEntity */
  interface PreferencesSubscription {
    key: string;
    optedIn: any;
    editableState: string;
  }

  /** Auto-generated from Suma::API::Entities::RegistrationLinkEntity */
  interface RegistrationLink {
    organizationName: string;
    intro: any;
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
    contentLength: any;
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
    /** manually corrected: array (with: LedgerLineEntity) */
    items: LedgerLine[];
    ledgerId: number;
  }

  /** Auto-generated from Suma::API::Ledgers::LedgersViewEntity */
  interface LedgersView {
    totalBalance: Money;
    lifetimeSavings: Money;
    /** manually corrected: array (with: LedgerEntity) */
    ledgers: Ledger[];
    /** manually corrected: array (with: LedgerLineEntity) */
    recentLines: LedgerLine[];
  }

  /** Auto-generated from Suma::API::Me::DashboardAlertEntity */
  interface DashboardAlert {
    localizationKey: string;
    localizationParams: any;
    variant: any;
  }

  /** Auto-generated from Suma::API::Me::DashboardEntity */
  interface Dashboard {
    cashBalance: Money;
    /** manually corrected: array (with: ProgramEntity) */
    programs: Program[];
    /** manually corrected: array (with: DashboardAlertEntity) */
    alerts: DashboardAlert[];
  }

  /** Auto-generated from Suma::API::Me::ProgramEntity */
  interface Program {
    name: string;
    description: string;
    image: Image;
    periodBegin: string;
    periodEnd: string;
    appLink: string;
    appLinkText: any;
  }

  /** Auto-generated from Suma::API::Mobility::MobilityDetailedVehicleEntity */
  interface MobilityDetailedVehicle {
    precision: any;
    vendorService: VendorService;
    vehicleId: number;
    loc: any;
    rate: Rate;
    subsidyMatchPercentage: any;
    deeplink: any;
    gotoPrivateAccount: any;
    usageProhibitedReason: string;
  }

  /** Auto-generated from Suma::API::Mobility::MobilityMapEntity */
  interface MobilityMap {
    precision: any;
    refresh: any;
    /** manually corrected: array (with: MobilityMapProviderEntity) */
    providers: MobilityMapProvider[];
    escooter: MobilityMapVehicle;
    ebike: MobilityMapVehicle;
  }

  /** Auto-generated from Suma::API::Mobility::MobilityMapFeaturesEntity */
  interface MobilityMapFeatures {
    /** manually corrected: array (with: MobilityMapRestrictionEntity) */
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

  /** Auto-generated from Suma::API::Mobility::MobilityMapRestrictionEntity */
  interface MobilityMapRestriction {
    restriction: any;
    multipolygon: any;
    bounds: any;
  }

  /** Auto-generated from Suma::API::Mobility::MobilityMapVehicleEntity */
  interface MobilityMapVehicle {
    c: any;
    p: any;
    d: any;
    o: any;
  }

  /** Auto-generated from Suma::API::Mobility::MobilityTripCollectionEntity */
  interface MobilityTripCollection {
    object: string;
    currentPage: number;
    pageCount: number;
    totalCount: number;
    hasMore: boolean;
    url: string;
    /** manually corrected: array (with: MobilityTripEntity) */
    items: MobilityTrip[];
    ongoing: MobilityTrip;
    weeks: any;
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
    usableForFunding: any;
    status: string;
    expiresAt: string;
    institution: any;
    name: string;
    last4: string;
    key: string;
    /** manually corrected: array (with: PaymentInstrumentEntity) */
    allPaymentInstruments: PaymentInstrument[];
  }

  /** Auto-generated from Suma::API::Payments::FundingTransactionEntity */
  interface FundingTransaction {
    id: number;
    createdAt: string;
    status: string;
    amount: Money;
    memo: any;
  }

  /** Auto-generated from Suma::API::Preferences::PublicPrefsEntity */
  interface PublicPrefs {
    /** manually corrected: array (with: PreferencesSubscriptionEntity) */
    subscriptions: PreferencesSubscription[];
  }

  /** Auto-generated from Suma::API::Preferences::PublicPrefsMemberEntity */
  interface PublicPrefsMember {
    email: string;
    name: string;
    phone: string;
    preferences: PublicPrefs;
  }
}

export {};
