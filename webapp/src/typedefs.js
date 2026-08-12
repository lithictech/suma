// Auto-generated typedefs from Grape::Entity
// Generated: 2026-08-11 15:39:14
// Entities: Money, Suma::API::AnonProxy::AnonProxyVendorAccountEntity, Suma::API::AnonProxy::AnonProxyVendorAccountPollResultEntity, Suma::API::AnonProxy::AnonProxyVendorAccountUIStateEntity, Suma::API::Auth::AuthFlowMemberEntity, Suma::API::Commerce::BaseOfferingProductEntity, Suma::API::Commerce::CartEntity, Suma::API::Commerce::CartItemEntity, Suma::API::Commerce::ChargeContributionEntity, Suma::API::Commerce::CheckoutConfirmationEntity, Suma::API::Commerce::CheckoutConfirmationItemEntity, Suma::API::Commerce::CheckoutConfirmationProductEntity, Suma::API::Commerce::CheckoutEntity, Suma::API::Commerce::CheckoutItemEntity, Suma::API::Commerce::CheckoutProductEntity, Suma::API::Commerce::DetailedOrderHistoryEntity, Suma::API::Commerce::FulfillmentOptionAddressEntity, Suma::API::Commerce::FulfillmentOptionEntity, Suma::API::Commerce::OfferingEntity, Suma::API::Commerce::OfferingWithContextEntity, Suma::API::Commerce::OrderHistoryCollection, Suma::API::Commerce::OrderHistoryFundingTransactionEntity, Suma::API::Commerce::OrderHistoryItemEntity, Suma::API::Commerce::PricedOfferingProductEntity, Suma::API::Commerce::SimpleOrderHistoryEntity, Suma::API::Commerce::UnclaimedOrderCollection, Suma::API::Commerce::VendorEntity, Suma::API::Entities::BaseEntity, Suma::API::Entities::CurrencyEntity, Suma::API::Entities::CurrentMemberEntity, Suma::API::Entities::ImageEntity, Suma::API::Entities::LedgerEntity, Suma::API::Entities::LedgerLineEntity, Suma::API::Entities::LedgerLineUsageDetailsEntity, Suma::API::Entities::LocaleEntity, Suma::API::Entities::MemberPreferencesEntity, Suma::API::Entities::MobilityChargeEntity, Suma::API::Entities::MobilityChargeLineItemEntity, Suma::API::Entities::MobilityTripEntity, Suma::API::Entities::PaymentInstrumentEntity, Suma::API::Entities::PreferencesSubscriptionEntity, Suma::API::Entities::RegistrationLinkEntity, Suma::API::Entities::VendorServiceEntity, Suma::API::Images::UploadedFileEntity, Suma::API::Ledgers::LedgerLinesEntity, Suma::API::Ledgers::LedgersViewEntity, Suma::API::Me::DashboardAlertEntity, Suma::API::Me::DashboardEntity, Suma::API::Me::ProgramEntity, Suma::API::Mobility::MobilityDetailedVehicleEntity, Suma::API::Mobility::MobilityMapEntity, Suma::API::Mobility::MobilityMapFeaturesEntity, Suma::API::Mobility::MobilityMapProviderEntity, Suma::API::Mobility::MobilityMapRestrictionEntity, Suma::API::Mobility::MobilityMapVehicleEntity, Suma::API::Mobility::MobilityTripCollectionEntity, Suma::API::Mobility::RateEntity, Suma::API::Mobility::SimpleRateEntity, Suma::API::PaymentInstruments::MutationPaymentInstrumentEntity, Suma::API::Payments::FundingTransactionEntity, Suma::API::Preferences::PublicPrefsEntity, Suma::API::Preferences::PublicPrefsMemberEntity

/**
 * @typedef {object} Money
 * @description Auto-generated from Money
 * @property {number} cents
 * @property {string} currency
 */

/**
 * @typedef {object} AnonProxyVendorAccount
 * @description Auto-generated from Suma::API::AnonProxy::AnonProxyVendorAccountEntity
 * @property {number} id
 * @property {string} magicLink
 * @property {string} vendorName
 * @property {string} vendorSlug
 * @property {Image} vendorImage
 * @property {AnonProxyVendorAccountUIState} uiStateV1
 */

/**
 * @typedef {object} AnonProxyVendorAccountPollResult
 * @description Auto-generated from Suma::API::AnonProxy::AnonProxyVendorAccountPollResultEntity
 * @property {any} foundChange
 * @property {any} successInstructions
 * @property {AnonProxyVendorAccount} vendorAccount
 */

/**
 * @typedef {object} AnonProxyVendorAccountUIState
 * @description Auto-generated from Suma::API::AnonProxy::AnonProxyVendorAccountUIStateEntity
 * @property {any} indexCardMode
 * @property {boolean} needsLinking
 * @property {any} requiresPaymentMethod
 * @property {any} hasPaymentMethod
 * @property {any} balancePayoffNeeded
 * @property {any} showPaymentStep
 * @property {any} termStepIndex
 * @property {any} linkStepIndex
 * @property {any} descriptionText
 * @property {any} termsText
 * @property {any} helpText
 */

/**
 * @typedef {object} AuthFlowMember
 * @description Auto-generated from Suma::API::Auth::AuthFlowMemberEntity
 * @property {any} requiresTermsAgreement
 */

/**
 * @typedef {object} BaseOfferingProduct
 * @description Auto-generated from Suma::API::Commerce::BaseOfferingProductEntity
 * @property {string} name
 * @property {string} description
 * @property {number} offeringId
 * @property {number} productId
 * @property {Vendor} vendor
 * @property {Image} images
 */

/**
 * @typedef {object} Cart
 * @description Auto-generated from Suma::API::Commerce::CartEntity
 * @property {any} cartHash
 * @property {CartItem} items
 * @property {Money} customerCost
 * @property {Money} noncashLedgerContributionAmount
 * @property {Money} cashCost
 * @property {any} cartFull
 */

/**
 * @typedef {object} CartItem
 * @description Auto-generated from Suma::API::Commerce::CartItemEntity
 * @property {number} quantity
 * @property {number} productId
 */

/**
 * @typedef {object} ChargeContribution
 * @description Auto-generated from Suma::API::Commerce::ChargeContributionEntity
 * @property {Money} amount
 * @property {string} name
 */

/**
 * @typedef {object} CheckoutConfirmation
 * @description Auto-generated from Suma::API::Commerce::CheckoutConfirmationEntity
 * @property {number} id
 * @property {CheckoutConfirmationItem} items
 * @property {Offering} offering
 * @property {FulfillmentOption} fulfillmentOption
 */

/**
 * @typedef {object} CheckoutConfirmationItem
 * @description Auto-generated from Suma::API::Commerce::CheckoutConfirmationItemEntity
 * @property {CheckoutConfirmationProduct} product
 * @property {number} quantity
 */

/**
 * @typedef {object} CheckoutConfirmationProduct
 * @description Auto-generated from Suma::API::Commerce::CheckoutConfirmationProductEntity
 * @property {string} name
 * @property {string} description
 * @property {number} offeringId
 * @property {number} productId
 * @property {Vendor} vendor
 * @property {Image} images
 */

/**
 * @typedef {object} Checkout
 * @description Auto-generated from Suma::API::Commerce::CheckoutEntity
 * @property {number} id
 * @property {CheckoutItem} items
 * @property {Offering} offering
 * @property {number} fulfillmentOptionId
 * @property {FulfillmentOption} availableFulfillmentOptions
 * @property {PaymentInstrument} paymentInstrument
 * @property {PaymentInstrument} availablePaymentInstruments
 * @property {PaymentInstrument} unavailablePaymentInstruments
 * @property {Money} customerCost
 * @property {Money} undiscountedCost
 * @property {Money} savings
 * @property {Money} handling
 * @property {Money} taxableCost
 * @property {Money} tax
 * @property {Money} total
 * @property {Money} chargeableTotal
 * @property {any} requiresPaymentInstrument
 * @property {string} checkoutProhibitedReason
 * @property {ChargeContribution} existingFundsAvailable
 */

/**
 * @typedef {object} CheckoutItem
 * @description Auto-generated from Suma::API::Commerce::CheckoutItemEntity
 * @property {CheckoutProduct} product
 * @property {number} quantity
 */

/**
 * @typedef {object} CheckoutProduct
 * @description Auto-generated from Suma::API::Commerce::CheckoutProductEntity
 * @property {string} name
 * @property {string} description
 * @property {number} offeringId
 * @property {number} productId
 * @property {Vendor} vendor
 * @property {Image} images
 * @property {any} listable
 * @property {number} maxQuantity
 * @property {any} outOfStock
 * @property {string} outOfStockReason
 * @property {any} outOfStockReasonText
 * @property {Money} displayableNoncashLedgerContributionAmount
 * @property {Money} displayableCashPrice
 * @property {boolean} isDiscounted
 * @property {Money} customerPrice
 * @property {Money} undiscountedPrice
 * @property {Money} discountAmount
 */

/**
 * @typedef {object} DetailedOrderHistory
 * @description Auto-generated from Suma::API::Commerce::DetailedOrderHistoryEntity
 * @property {number} id
 * @property {any} serial
 * @property {string} createdAt
 * @property {string} fulfilledAt
 * @property {Money} total
 * @property {Image} image
 * @property {string} availableForPickupAt
 * @property {OrderHistoryItem} items
 * @property {number} offeringId
 * @property {string} offeringDescription
 * @property {any} fulfillmentConfirmation
 * @property {FulfillmentOption} fulfillmentOption
 * @property {FulfillmentOption} fulfillmentOptionsForEditing
 * @property {any} fulfillmentOptionEditable
 * @property {string} orderStatus
 * @property {boolean} canClaim
 * @property {Money} customerCost
 * @property {Money} undiscountedCost
 * @property {Money} savings
 * @property {Money} handling
 * @property {Money} taxableCost
 * @property {Money} tax
 * @property {OrderHistoryFundingTransaction} fundingTransactions
 */

/**
 * @typedef {object} FulfillmentOptionAddress
 * @description Auto-generated from Suma::API::Commerce::FulfillmentOptionAddressEntity
 * @property {any} oneLineAddress
 */

/**
 * @typedef {object} FulfillmentOption
 * @description Auto-generated from Suma::API::Commerce::FulfillmentOptionEntity
 * @property {number} id
 * @property {string} description
 * @property {FulfillmentOptionAddress} address
 */

/**
 * @typedef {object} Offering
 * @description Auto-generated from Suma::API::Commerce::OfferingEntity
 * @property {number} id
 * @property {string} description
 * @property {any} fulfillmentPrompt
 * @property {any} fulfillmentConfirmation
 * @property {any} fulfillmentInstructions
 * @property {string} closesAt
 * @property {Image} image
 * @property {string} appLink
 */

/**
 * @typedef {object} OfferingWithContext
 * @description Auto-generated from Suma::API::Commerce::OfferingWithContextEntity
 * @property {Offering} offering
 * @property {any} items
 * @property {Vendor} vendors
 * @property {Cart} cart
 */

/**
 * @typedef {object} OrderHistoryCollection
 * @description Auto-generated from Suma::API::Commerce::OrderHistoryCollection
 * @property {string} object
 * @property {number} currentPage
 * @property {number} pageCount
 * @property {number} totalCount
 * @property {boolean} hasMore
 * @property {string} url
 * @property {SimpleOrderHistory} items
 * @property {DetailedOrderHistory} detailedOrders
 */

/**
 * @typedef {object} OrderHistoryFundingTransaction
 * @description Auto-generated from Suma::API::Commerce::OrderHistoryFundingTransactionEntity
 * @property {Money} amount
 * @property {string} label
 */

/**
 * @typedef {object} OrderHistoryItem
 * @description Auto-generated from Suma::API::Commerce::OrderHistoryItemEntity
 * @property {number} quantity
 * @property {string} name
 * @property {string} description
 * @property {Image} image
 * @property {Money} customerPrice
 */

/**
 * @typedef {object} PricedOfferingProduct
 * @description Auto-generated from Suma::API::Commerce::PricedOfferingProductEntity
 * @property {string} name
 * @property {string} description
 * @property {number} offeringId
 * @property {number} productId
 * @property {Vendor} vendor
 * @property {Image} images
 * @property {any} listable
 * @property {number} maxQuantity
 * @property {any} outOfStock
 * @property {string} outOfStockReason
 * @property {any} outOfStockReasonText
 * @property {Money} displayableNoncashLedgerContributionAmount
 * @property {Money} displayableCashPrice
 * @property {boolean} isDiscounted
 * @property {Money} customerPrice
 * @property {Money} undiscountedPrice
 * @property {Money} discountAmount
 */

/**
 * @typedef {object} SimpleOrderHistory
 * @description Auto-generated from Suma::API::Commerce::SimpleOrderHistoryEntity
 * @property {number} id
 * @property {any} serial
 * @property {string} createdAt
 * @property {string} fulfilledAt
 * @property {Money} total
 * @property {Image} image
 * @property {string} availableForPickupAt
 */

/**
 * @typedef {object} UnclaimedOrderCollection
 * @description Auto-generated from Suma::API::Commerce::UnclaimedOrderCollection
 * @property {string} object
 * @property {number} currentPage
 * @property {number} pageCount
 * @property {number} totalCount
 * @property {boolean} hasMore
 * @property {string} url
 * @property {DetailedOrderHistory} items
 */

/**
 * @typedef {object} Vendor
 * @description Auto-generated from Suma::API::Commerce::VendorEntity
 * @property {number} id
 * @property {string} name
 */

/**
 * @typedef {object} Base
 * @description Auto-generated from Suma::API::Entities::BaseEntity
 */

/**
 * @typedef {object} Currency
 * @description Auto-generated from Suma::API::Entities::CurrencyEntity
 * @property {any} symbol
 * @property {string} code
 * @property {number} fundingMinimumCents
 * @property {number} fundingMaximumCents
 * @property {number} fundingStepCents
 * @property {any} centsInDollar
 * @property {any} paymentMethodTypes
 */

/**
 * @typedef {object} CurrentMember
 * @description Auto-generated from Suma::API::Entities::CurrentMemberEntity
 * @property {number} id
 * @property {string} createdAt
 * @property {string} email
 * @property {string} name
 * @property {string} phone
 * @property {any} onboarded
 * @property {any} roleAccess
 * @property {number} unclaimedOrdersCount
 * @property {MobilityTrip} ongoingTrip
 * @property {any} readOnlyMode
 * @property {string} readOnlyReason
 * @property {PaymentInstrument} paymentInstruments
 * @property {CurrentMember} adminMember
 * @property {any} showPrivateAccounts
 * @property {MemberPreferences} preferences
 * @property {any} hasOrderHistory
 * @property {Money} chargeableCashBalance
 * @property {any} finishedSurveyTopics
 * @property {RegistrationLink} registrationLink
 */

/**
 * @typedef {object} Image
 * @description Auto-generated from Suma::API::Entities::ImageEntity
 * @property {any} caption
 * @property {string} url
 */

/**
 * @typedef {object} Ledger
 * @description Auto-generated from Suma::API::Entities::LedgerEntity
 * @property {number} id
 * @property {string} name
 * @property {any} contributionText
 * @property {Money} balance
 */

/**
 * @typedef {object} LedgerLine
 * @description Auto-generated from Suma::API::Entities::LedgerLineEntity
 * @property {number} id
 * @property {number} opaqueId
 * @property {string} at
 * @property {any} memo
 * @property {Money} amount
 * @property {LedgerLineUsageDetails} usageDetails
 */

/**
 * @typedef {object} LedgerLineUsageDetails
 * @description Auto-generated from Suma::API::Entities::LedgerLineUsageDetailsEntity
 * @property {string} code
 * @property {any} args
 */

/**
 * @typedef {object} Locale
 * @description Auto-generated from Suma::API::Entities::LocaleEntity
 * @property {string} code
 * @property {any} language
 * @property {any} native
 */

/**
 * @typedef {object} MemberPreferences
 * @description Auto-generated from Suma::API::Entities::MemberPreferencesEntity
 * @property {PreferencesSubscription} subscriptions
 */

/**
 * @typedef {object} MobilityCharge
 * @description Auto-generated from Suma::API::Entities::MobilityChargeEntity
 * @property {Money} undiscountedCost
 * @property {Money} customerCost
 * @property {Money} savings
 * @property {MobilityChargeLineItem} lineItems
 */

/**
 * @typedef {object} MobilityChargeLineItem
 * @description Auto-generated from Suma::API::Entities::MobilityChargeLineItemEntity
 * @property {Money} amount
 * @property {any} memo
 */

/**
 * @typedef {object} MobilityTrip
 * @description Auto-generated from Suma::API::Entities::MobilityTripEntity
 * @property {number} id
 * @property {number} vehicleId
 * @property {string} vehicleType
 * @property {VendorService} provider
 * @property {number} beginLat
 * @property {number} beginLng
 * @property {any} beginAddress
 * @property {string} beganAt
 * @property {number} endLat
 * @property {number} endLng
 * @property {any} endAddress
 * @property {string} endedAt
 * @property {any} ongoing
 * @property {MobilityCharge} charge
 * @property {any} minutes
 * @property {Image} image
 */

/**
 * @typedef {object} PaymentInstrument
 * @description Auto-generated from Suma::API::Entities::PaymentInstrumentEntity
 * @property {number} id
 * @property {string} createdAt
 * @property {number} paymentInstrumentId
 * @property {string} paymentMethodType
 * @property {any} usableForFunding
 * @property {string} status
 * @property {string} expiresAt
 * @property {any} institution
 * @property {string} name
 * @property {string} last4
 * @property {string} key
 */

/**
 * @typedef {object} PreferencesSubscription
 * @description Auto-generated from Suma::API::Entities::PreferencesSubscriptionEntity
 * @property {string} key
 * @property {any} optedIn
 * @property {string} editableState
 */

/**
 * @typedef {object} RegistrationLink
 * @description Auto-generated from Suma::API::Entities::RegistrationLinkEntity
 * @property {string} organizationName
 * @property {any} intro
 */

/**
 * @typedef {object} VendorService
 * @description Auto-generated from Suma::API::Entities::VendorServiceEntity
 * @property {number} id
 * @property {string} name
 * @property {string} slug
 * @property {string} vendorName
 * @property {string} vendorSlug
 */

/**
 * @typedef {object} UploadedFile
 * @description Auto-generated from Suma::API::Images::UploadedFileEntity
 * @property {number} opaqueId
 * @property {string} contentType
 * @property {any} contentLength
 * @property {string} absoluteUrl
 */

/**
 * @typedef {object} LedgerLines
 * @description Auto-generated from Suma::API::Ledgers::LedgerLinesEntity
 * @property {string} object
 * @property {number} currentPage
 * @property {number} pageCount
 * @property {number} totalCount
 * @property {boolean} hasMore
 * @property {string} url
 * @property {LedgerLine} items
 * @property {number} ledgerId
 */

/**
 * @typedef {object} LedgersView
 * @description Auto-generated from Suma::API::Ledgers::LedgersViewEntity
 * @property {Money} totalBalance
 * @property {Money} lifetimeSavings
 * @property {Ledger} ledgers
 * @property {LedgerLine} recentLines
 */

/**
 * @typedef {object} DashboardAlert
 * @description Auto-generated from Suma::API::Me::DashboardAlertEntity
 * @property {string} localizationKey
 * @property {any} localizationParams
 * @property {any} variant
 */

/**
 * @typedef {object} Dashboard
 * @description Auto-generated from Suma::API::Me::DashboardEntity
 * @property {Money} cashBalance
 * @property {Program} programs
 * @property {DashboardAlert} alerts
 */

/**
 * @typedef {object} Program
 * @description Auto-generated from Suma::API::Me::ProgramEntity
 * @property {string} name
 * @property {string} description
 * @property {Image} image
 * @property {string} periodBegin
 * @property {string} periodEnd
 * @property {string} appLink
 * @property {any} appLinkText
 */

/**
 * @typedef {object} MobilityDetailedVehicle
 * @description Auto-generated from Suma::API::Mobility::MobilityDetailedVehicleEntity
 * @property {any} precision
 * @property {VendorService} vendorService
 * @property {number} vehicleId
 * @property {any} loc
 * @property {Rate} rate
 * @property {any} subsidyMatchPercentage
 * @property {any} deeplink
 * @property {any} gotoPrivateAccount
 * @property {string} usageProhibitedReason
 */

/**
 * @typedef {object} MobilityMap
 * @description Auto-generated from Suma::API::Mobility::MobilityMapEntity
 * @property {any} precision
 * @property {any} refresh
 * @property {MobilityMapProvider} providers
 * @property {MobilityMapVehicle} escooter
 * @property {MobilityMapVehicle} ebike
 */

/**
 * @typedef {object} MobilityMapFeatures
 * @description Auto-generated from Suma::API::Mobility::MobilityMapFeaturesEntity
 * @property {MobilityMapRestriction} restrictions
 */

/**
 * @typedef {object} MobilityMapProvider
 * @description Auto-generated from Suma::API::Mobility::MobilityMapProviderEntity
 * @property {number} id
 * @property {string} name
 * @property {string} slug
 * @property {string} vendorName
 * @property {string} vendorSlug
 * @property {SimpleRate} rate
 * @property {string} usageProhibitedReason
 */

/**
 * @typedef {object} MobilityMapRestriction
 * @description Auto-generated from Suma::API::Mobility::MobilityMapRestrictionEntity
 * @property {any} restriction
 * @property {any} multipolygon
 * @property {any} bounds
 */

/**
 * @typedef {object} MobilityMapVehicle
 * @description Auto-generated from Suma::API::Mobility::MobilityMapVehicleEntity
 * @property {any} c
 * @property {any} p
 * @property {any} d
 * @property {any} o
 */

/**
 * @typedef {object} MobilityTripCollection
 * @description Auto-generated from Suma::API::Mobility::MobilityTripCollectionEntity
 * @property {string} object
 * @property {number} currentPage
 * @property {number} pageCount
 * @property {number} totalCount
 * @property {boolean} hasMore
 * @property {string} url
 * @property {MobilityTrip} items
 * @property {MobilityTrip} ongoing
 * @property {any} weeks
 */

/**
 * @typedef {object} Rate
 * @description Auto-generated from Suma::API::Mobility::RateEntity
 * @property {number} id
 * @property {Money} surcharge
 * @property {Money} unitAmount
 * @property {string} name
 * @property {SimpleRate} undiscountedRate
 */

/**
 * @typedef {object} SimpleRate
 * @description Auto-generated from Suma::API::Mobility::SimpleRateEntity
 * @property {number} id
 * @property {Money} surcharge
 * @property {Money} unitAmount
 */

/**
 * @typedef {object} MutationPaymentInstrument
 * @description Auto-generated from Suma::API::PaymentInstruments::MutationPaymentInstrumentEntity
 * @property {number} id
 * @property {string} createdAt
 * @property {number} paymentInstrumentId
 * @property {string} paymentMethodType
 * @property {any} usableForFunding
 * @property {string} status
 * @property {string} expiresAt
 * @property {any} institution
 * @property {string} name
 * @property {string} last4
 * @property {string} key
 * @property {PaymentInstrument} allPaymentInstruments
 */

/**
 * @typedef {object} FundingTransaction
 * @description Auto-generated from Suma::API::Payments::FundingTransactionEntity
 * @property {number} id
 * @property {string} createdAt
 * @property {string} status
 * @property {Money} amount
 * @property {any} memo
 */

/**
 * @typedef {object} PublicPrefs
 * @description Auto-generated from Suma::API::Preferences::PublicPrefsEntity
 * @property {PreferencesSubscription} subscriptions
 */

/**
 * @typedef {object} PublicPrefsMember
 * @description Auto-generated from Suma::API::Preferences::PublicPrefsMemberEntity
 * @property {string} email
 * @property {string} name
 * @property {string} phone
 * @property {PublicPrefs} preferences
 */
