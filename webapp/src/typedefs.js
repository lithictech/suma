// Auto-generated JSDoc typedefs from Grape::Entity
// Generated: 2026-04-26 10:35:54
// Entities: Suma::API::AnonProxy::AnonProxyVendorAccountEntity, Suma::API::AnonProxy::AnonProxyVendorAccountPollResultEntity, Suma::API::AnonProxy::AnonProxyVendorAccountUIStateEntity, Suma::API::Auth::AuthFlowMemberEntity, Suma::API::Commerce::BaseOfferingProductEntity, Suma::API::Commerce::CartEntity, Suma::API::Commerce::CartItemEntity, Suma::API::Commerce::ChargeContributionEntity, Suma::API::Commerce::CheckoutConfirmationEntity, Suma::API::Commerce::CheckoutConfirmationItemEntity, Suma::API::Commerce::CheckoutConfirmationProductEntity, Suma::API::Commerce::CheckoutEntity, Suma::API::Commerce::CheckoutItemEntity, Suma::API::Commerce::CheckoutProductEntity, Suma::API::Commerce::DetailedOrderHistoryEntity, Suma::API::Commerce::FulfillmentOptionAddressEntity, Suma::API::Commerce::FulfillmentOptionEntity, Suma::API::Commerce::OfferingEntity, Suma::API::Commerce::OfferingWithContextEntity, Suma::API::Commerce::OrderHistoryCollection, Suma::API::Commerce::OrderHistoryFundingTransactionEntity, Suma::API::Commerce::OrderHistoryItemEntity, Suma::API::Commerce::PricedOfferingProductEntity, Suma::API::Commerce::SimpleOrderHistoryEntity, Suma::API::Commerce::UnclaimedOrderCollection, Suma::API::Commerce::VendorEntity, Suma::API::Entities::BaseEntity, Suma::API::Entities::CurrencyEntity, Suma::API::Entities::CurrentMemberEntity, Suma::API::Entities::ImageEntity, Suma::API::Entities::LedgerEntity, Suma::API::Entities::LedgerLineEntity, Suma::API::Entities::LedgerLineUsageDetailsEntity, Suma::API::Entities::LocaleEntity, Suma::API::Entities::MemberPreferencesEntity, Suma::API::Entities::MobilityChargeEntity, Suma::API::Entities::MobilityChargeLineItemEntity, Suma::API::Entities::MobilityTripEntity, Suma::API::Entities::PaymentInstrumentEntity, Suma::API::Entities::PreferencesSubscriptionEntity, Suma::API::Entities::VendorServiceEntity, Suma::API::Images::UploadedFileEntity, Suma::API::Ledgers::LedgerLinesEntity, Suma::API::Ledgers::LedgersViewEntity, Suma::API::Me::DashboardAlertEntity, Suma::API::Me::DashboardEntity, Suma::API::Me::ProgramEntity, Suma::API::Mobility::MobilityDetailedVehicleEntity, Suma::API::Mobility::MobilityMapEntity, Suma::API::Mobility::MobilityMapFeaturesEntity, Suma::API::Mobility::MobilityMapProviderEntity, Suma::API::Mobility::MobilityMapRestrictionEntity, Suma::API::Mobility::MobilityMapVehicleEntity, Suma::API::Mobility::MobilityTripCollectionEntity, Suma::API::Mobility::RateEntity, Suma::API::Mobility::SimpleRateEntity, Suma::API::PaymentInstruments::MutationPaymentInstrumentEntity, Suma::API::Payments::FundingTransactionEntity, Suma::API::Preferences::PublicPrefsEntity, Suma::API::Preferences::PublicPrefsMemberEntity

/**
 * @typedef {Object} AnonProxyVendorAccount
 * @description Auto-generated from Suma::API::AnonProxy::AnonProxyVendorAccountEntity
 * @property {number} id
 * @property {string} magicLink
 * @property {string} vendorName
 * @property {string} vendorSlug
 * @property {Image} vendorImage
 * @property {AnonProxyVendorAccountUIState} uiStateV1
 */

/**
 * @typedef {Object} AnonProxyVendorAccountPollResult
 * @description Auto-generated from Suma::API::AnonProxy::AnonProxyVendorAccountPollResultEntity
 * @property {?} foundChange
 * @property {?} successInstructions
 * @property {AnonProxyVendorAccount} vendorAccount
 */

/**
 * @typedef {Object} AnonProxyVendorAccountUIState
 * @description Auto-generated from Suma::API::AnonProxy::AnonProxyVendorAccountUIStateEntity
 * @property {?} indexCardMode
 * @property {boolean} needsLinking
 * @property {?} requiresPaymentMethod
 * @property {?} hasPaymentMethod
 * @property {?} promptForPaymentMethod
 * @property {?} descriptionText
 * @property {?} termsText
 * @property {?} helpText
 */

/**
 * @typedef {Object} AuthFlowMember
 * @description Auto-generated from Suma::API::Auth::AuthFlowMemberEntity
 * @property {?} requiresTermsAgreement
 */

/**
 * @typedef {Object} BaseOfferingProduct
 * @description Auto-generated from Suma::API::Commerce::BaseOfferingProductEntity
 * @property {string} name
 * @property {string} description
 * @property {number} offeringId
 * @property {number} productId
 * @property {Vendor} vendor
 * @property {Image} images
 */

/**
 * @typedef {Object} Cart
 * @description Auto-generated from Suma::API::Commerce::CartEntity
 * @property {?} cartHash
 * @property {CartItem} items
 * @property {Money} customerCost
 * @property {Money} noncashLedgerContributionAmount
 * @property {Money} cashCost
 * @property {?} cartFull
 */

/**
 * @typedef {Object} CartItem
 * @description Auto-generated from Suma::API::Commerce::CartItemEntity
 * @property {number} quantity
 * @property {number} productId
 */

/**
 * @typedef {Object} ChargeContribution
 * @description Auto-generated from Suma::API::Commerce::ChargeContributionEntity
 * @property {Money} amount
 * @property {string} name
 */

/**
 * @typedef {Object} CheckoutConfirmation
 * @description Auto-generated from Suma::API::Commerce::CheckoutConfirmationEntity
 * @property {number} id
 * @property {CheckoutConfirmationItem} items
 * @property {Offering} offering
 * @property {FulfillmentOption} fulfillmentOption
 */

/**
 * @typedef {Object} CheckoutConfirmationItem
 * @description Auto-generated from Suma::API::Commerce::CheckoutConfirmationItemEntity
 * @property {CheckoutConfirmationProduct} product
 * @property {number} quantity
 */

/**
 * @typedef {Object} CheckoutConfirmationProduct
 * @description Auto-generated from Suma::API::Commerce::CheckoutConfirmationProductEntity
 * @property {string} name
 * @property {string} description
 * @property {number} offeringId
 * @property {number} productId
 * @property {Vendor} vendor
 * @property {Image} images
 * @property {Vendor} vendor
 */

/**
 * @typedef {Object} Checkout
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
 * @property {?} requiresPaymentInstrument
 * @property {string} checkoutProhibitedReason
 * @property {ChargeContribution} existingFundsAvailable
 */

/**
 * @typedef {Object} CheckoutItem
 * @description Auto-generated from Suma::API::Commerce::CheckoutItemEntity
 * @property {CheckoutProduct} product
 * @property {number} quantity
 */

/**
 * @typedef {Object} CheckoutProduct
 * @description Auto-generated from Suma::API::Commerce::CheckoutProductEntity
 * @property {string} name
 * @property {string} description
 * @property {number} offeringId
 * @property {number} productId
 * @property {Vendor} vendor
 * @property {Image} images
 * @property {?} listable
 * @property {number} maxQuantity
 * @property {?} outOfStock
 * @property {string} outOfStockReason
 * @property {?} outOfStockReasonText
 * @property {Money} displayableNoncashLedgerContributionAmount
 * @property {Money} displayableCashPrice
 * @property {boolean} isDiscounted
 * @property {Money} customerPrice
 * @property {Money} undiscountedPrice
 * @property {Money} discountAmount
 * @property {Vendor} vendor
 */

/**
 * @typedef {Object} DetailedOrderHistory
 * @description Auto-generated from Suma::API::Commerce::DetailedOrderHistoryEntity
 * @property {number} id
 * @property {?} serial
 * @property {string} createdAt
 * @property {string} fulfilledAt
 * @property {Money} total
 * @property {Image} image
 * @property {string} availableForPickupAt
 * @property {OrderHistoryItem} items
 * @property {number} offeringId
 * @property {string} offeringDescription
 * @property {?} fulfillmentConfirmation
 * @property {FulfillmentOption} fulfillmentOption
 * @property {FulfillmentOption} fulfillmentOptionsForEditing
 * @property {?} fulfillmentOptionEditable
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
 * @typedef {Object} FulfillmentOptionAddress
 * @description Auto-generated from Suma::API::Commerce::FulfillmentOptionAddressEntity
 * @property {?} oneLineAddress
 */

/**
 * @typedef {Object} FulfillmentOption
 * @description Auto-generated from Suma::API::Commerce::FulfillmentOptionEntity
 * @property {number} id
 * @property {string} description
 * @property {FulfillmentOptionAddress} address
 */

/**
 * @typedef {Object} Offering
 * @description Auto-generated from Suma::API::Commerce::OfferingEntity
 * @property {number} id
 * @property {string} description
 * @property {?} fulfillmentPrompt
 * @property {?} fulfillmentConfirmation
 * @property {?} fulfillmentInstructions
 * @property {string} closesAt
 * @property {Image} image
 * @property {string} appLink
 */

/**
 * @typedef {Object} OfferingWithContext
 * @description Auto-generated from Suma::API::Commerce::OfferingWithContextEntity
 * @property {Offering} offering
 * @property {?} items
 * @property {Vendor} vendors
 * @property {Cart} cart
 */

/**
 * @typedef {Object} OrderHistoryCollection
 * @description Auto-generated from Suma::API::Commerce::OrderHistoryCollection
 * @property {?} object
 * @property {?} currentPage
 * @property {number} pageCount
 * @property {number} totalCount
 * @property {?} hasMore
 * @property {SimpleOrderHistory} items
 * @property {DetailedOrderHistory} detailedOrders
 */

/**
 * @typedef {Object} OrderHistoryFundingTransaction
 * @description Auto-generated from Suma::API::Commerce::OrderHistoryFundingTransactionEntity
 * @property {Money} amount
 * @property {string} label
 */

/**
 * @typedef {Object} OrderHistoryItem
 * @description Auto-generated from Suma::API::Commerce::OrderHistoryItemEntity
 * @property {number} quantity
 * @property {string} name
 * @property {string} description
 * @property {Image} image
 * @property {Money} customerPrice
 */

/**
 * @typedef {Object} PricedOfferingProduct
 * @description Auto-generated from Suma::API::Commerce::PricedOfferingProductEntity
 * @property {string} name
 * @property {string} description
 * @property {number} offeringId
 * @property {number} productId
 * @property {Vendor} vendor
 * @property {Image} images
 * @property {?} listable
 * @property {number} maxQuantity
 * @property {?} outOfStock
 * @property {string} outOfStockReason
 * @property {?} outOfStockReasonText
 * @property {Money} displayableNoncashLedgerContributionAmount
 * @property {Money} displayableCashPrice
 * @property {boolean} isDiscounted
 * @property {Money} customerPrice
 * @property {Money} undiscountedPrice
 * @property {Money} discountAmount
 */

/**
 * @typedef {Object} SimpleOrderHistory
 * @description Auto-generated from Suma::API::Commerce::SimpleOrderHistoryEntity
 * @property {number} id
 * @property {?} serial
 * @property {string} createdAt
 * @property {string} fulfilledAt
 * @property {Money} total
 * @property {Image} image
 * @property {string} availableForPickupAt
 */

/**
 * @typedef {Object} UnclaimedOrderCollection
 * @description Auto-generated from Suma::API::Commerce::UnclaimedOrderCollection
 * @property {?} object
 * @property {?} currentPage
 * @property {number} pageCount
 * @property {number} totalCount
 * @property {?} hasMore
 * @property {DetailedOrderHistory} items
 */

/**
 * @typedef {Object} Vendor
 * @description Auto-generated from Suma::API::Commerce::VendorEntity
 * @property {number} id
 * @property {string} name
 */

/**
 * @typedef {Object} Base
 * @description Auto-generated from Suma::API::Entities::BaseEntity
 */

/**
 * @typedef {Object} Currency
 * @description Auto-generated from Suma::API::Entities::CurrencyEntity
 * @property {?} symbol
 * @property {string} code
 * @property {number} fundingMinimumCents
 * @property {number} fundingMaximumCents
 * @property {number} fundingStepCents
 * @property {?} centsInDollar
 * @property {?} paymentMethodTypes
 */

/**
 * @typedef {Object} CurrentMember
 * @description Auto-generated from Suma::API::Entities::CurrentMemberEntity
 * @property {number} id
 * @property {string} createdAt
 * @property {string} email
 * @property {string} name
 * @property {string} phone
 * @property {?} onboarded
 * @property {?} roleAccess
 * @property {number} unclaimedOrdersCount
 * @property {MobilityTrip} ongoingTrip
 * @property {?} readOnlyMode
 * @property {string} readOnlyReason
 * @property {PaymentInstrument} paymentInstruments
 * @property {CurrentMember} adminMember
 * @property {?} showPrivateAccounts
 * @property {MemberPreferences} preferences
 * @property {?} hasOrderHistory
 * @property {?} finishedSurveyTopics
 */

/**
 * @typedef {Object} Image
 * @description Auto-generated from Suma::API::Entities::ImageEntity
 * @property {?} caption
 * @property {string} url
 */

/**
 * @typedef {Object} Ledger
 * @description Auto-generated from Suma::API::Entities::LedgerEntity
 * @property {number} id
 * @property {string} name
 * @property {?} contributionText
 * @property {Money} balance
 */

/**
 * @typedef {Object} LedgerLine
 * @description Auto-generated from Suma::API::Entities::LedgerLineEntity
 * @property {number} id
 * @property {number} opaqueId
 * @property {string} at
 * @property {?} memo
 * @property {Money} amount
 * @property {LedgerLineUsageDetails} usageDetails
 */

/**
 * @typedef {Object} LedgerLineUsageDetails
 * @description Auto-generated from Suma::API::Entities::LedgerLineUsageDetailsEntity
 * @property {string} code
 * @property {?} args
 */

/**
 * @typedef {Object} Locale
 * @description Auto-generated from Suma::API::Entities::LocaleEntity
 * @property {string} code
 * @property {?} language
 * @property {?} native
 */

/**
 * @typedef {Object} MemberPreferences
 * @description Auto-generated from Suma::API::Entities::MemberPreferencesEntity
 * @property {PreferencesSubscription} subscriptions
 */

/**
 * @typedef {Object} MobilityCharge
 * @description Auto-generated from Suma::API::Entities::MobilityChargeEntity
 * @property {Money} undiscountedCost
 * @property {Money} customerCost
 * @property {Money} savings
 * @property {MobilityChargeLineItem} lineItems
 */

/**
 * @typedef {Object} MobilityChargeLineItem
 * @description Auto-generated from Suma::API::Entities::MobilityChargeLineItemEntity
 * @property {Money} amount
 * @property {?} memo
 */

/**
 * @typedef {Object} MobilityTrip
 * @description Auto-generated from Suma::API::Entities::MobilityTripEntity
 * @property {number} id
 * @property {number} vehicleId
 * @property {string} vehicleType
 * @property {VendorService} provider
 * @property {number} beginLat
 * @property {number} beginLng
 * @property {?} beginAddress
 * @property {string} beganAt
 * @property {number} endLat
 * @property {number} endLng
 * @property {?} endAddress
 * @property {string} endedAt
 * @property {?} ongoing
 * @property {MobilityCharge} charge
 * @property {?} minutes
 * @property {Image} image
 */

/**
 * @typedef {Object} PaymentInstrument
 * @description Auto-generated from Suma::API::Entities::PaymentInstrumentEntity
 * @property {number} id
 * @property {string} createdAt
 * @property {number} paymentInstrumentId
 * @property {string} paymentMethodType
 * @property {?} usableForFunding
 * @property {string} status
 * @property {string} expiresAt
 * @property {?} institution
 * @property {string} name
 * @property {string} last4
 * @property {string} key
 */

/**
 * @typedef {Object} PreferencesSubscription
 * @description Auto-generated from Suma::API::Entities::PreferencesSubscriptionEntity
 * @property {string} key
 * @property {?} optedIn
 * @property {string} editableState
 */

/**
 * @typedef {Object} VendorService
 * @description Auto-generated from Suma::API::Entities::VendorServiceEntity
 * @property {number} id
 * @property {string} name
 * @property {string} slug
 * @property {string} vendorName
 * @property {string} vendorSlug
 */

/**
 * @typedef {Object} UploadedFile
 * @description Auto-generated from Suma::API::Images::UploadedFileEntity
 * @property {number} opaqueId
 * @property {string} contentType
 * @property {?} contentLength
 * @property {string} absoluteUrl
 */

/**
 * @typedef {Object} LedgerLines
 * @description Auto-generated from Suma::API::Ledgers::LedgerLinesEntity
 * @property {?} object
 * @property {?} currentPage
 * @property {number} pageCount
 * @property {number} totalCount
 * @property {?} hasMore
 * @property {LedgerLine} items
 * @property {number} ledgerId
 */

/**
 * @typedef {Object} LedgersView
 * @description Auto-generated from Suma::API::Ledgers::LedgersViewEntity
 * @property {Money} totalBalance
 * @property {Money} lifetimeSavings
 * @property {Ledger} ledgers
 * @property {LedgerLine} recentLines
 */

/**
 * @typedef {Object} DashboardAlert
 * @description Auto-generated from Suma::API::Me::DashboardAlertEntity
 * @property {string} localizationKey
 * @property {?} localizationParams
 * @property {?} variant
 */

/**
 * @typedef {Object} Dashboard
 * @description Auto-generated from Suma::API::Me::DashboardEntity
 * @property {Money} cashBalance
 * @property {Program} programs
 * @property {DashboardAlert} alerts
 */

/**
 * @typedef {Object} Program
 * @description Auto-generated from Suma::API::Me::ProgramEntity
 * @property {string} name
 * @property {string} description
 * @property {Image} image
 * @property {string} periodBegin
 * @property {string} periodEnd
 * @property {string} appLink
 * @property {?} appLinkText
 */

/**
 * @typedef {Object} MobilityDetailedVehicle
 * @description Auto-generated from Suma::API::Mobility::MobilityDetailedVehicleEntity
 * @property {?} precision
 * @property {VendorService} vendorService
 * @property {number} vehicleId
 * @property {?} loc
 * @property {Rate} rate
 * @property {?} subsidyMatchPercentage
 * @property {?} deeplink
 * @property {?} gotoPrivateAccount
 * @property {string} usageProhibitedReason
 */

/**
 * @typedef {Object} MobilityMap
 * @description Auto-generated from Suma::API::Mobility::MobilityMapEntity
 * @property {?} precision
 * @property {?} refresh
 * @property {MobilityMapProvider} providers
 * @property {MobilityMapVehicle} escooter
 * @property {MobilityMapVehicle} ebike
 */

/**
 * @typedef {Object} MobilityMapFeatures
 * @description Auto-generated from Suma::API::Mobility::MobilityMapFeaturesEntity
 * @property {MobilityMapRestriction} restrictions
 */

/**
 * @typedef {Object} MobilityMapProvider
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
 * @typedef {Object} MobilityMapRestriction
 * @description Auto-generated from Suma::API::Mobility::MobilityMapRestrictionEntity
 * @property {?} restriction
 * @property {?} multipolygon
 * @property {?} bounds
 */

/**
 * @typedef {Object} MobilityMapVehicle
 * @description Auto-generated from Suma::API::Mobility::MobilityMapVehicleEntity
 * @property {?} c
 * @property {?} p
 * @property {?} d
 * @property {?} o
 */

/**
 * @typedef {Object} MobilityTripCollection
 * @description Auto-generated from Suma::API::Mobility::MobilityTripCollectionEntity
 * @property {?} object
 * @property {?} currentPage
 * @property {number} pageCount
 * @property {number} totalCount
 * @property {?} hasMore
 * @property {MobilityTrip} items
 * @property {MobilityTrip} ongoing
 * @property {?} weeks
 */

/**
 * @typedef {Object} Rate
 * @description Auto-generated from Suma::API::Mobility::RateEntity
 * @property {number} id
 * @property {Money} surcharge
 * @property {Money} unitAmount
 * @property {string} name
 * @property {SimpleRate} undiscountedRate
 */

/**
 * @typedef {Object} SimpleRate
 * @description Auto-generated from Suma::API::Mobility::SimpleRateEntity
 * @property {number} id
 * @property {Money} surcharge
 * @property {Money} unitAmount
 */

/**
 * @typedef {Object} MutationPaymentInstrument
 * @description Auto-generated from Suma::API::PaymentInstruments::MutationPaymentInstrumentEntity
 * @property {number} id
 * @property {string} createdAt
 * @property {number} paymentInstrumentId
 * @property {string} paymentMethodType
 * @property {?} usableForFunding
 * @property {string} status
 * @property {string} expiresAt
 * @property {?} institution
 * @property {string} name
 * @property {string} last4
 * @property {string} key
 * @property {PaymentInstrument} allPaymentInstruments
 */

/**
 * @typedef {Object} FundingTransaction
 * @description Auto-generated from Suma::API::Payments::FundingTransactionEntity
 * @property {number} id
 * @property {string} createdAt
 * @property {string} status
 * @property {Money} amount
 * @property {?} memo
 */

/**
 * @typedef {Object} PublicPrefs
 * @description Auto-generated from Suma::API::Preferences::PublicPrefsEntity
 * @property {PreferencesSubscription} subscriptions
 */

/**
 * @typedef {Object} PublicPrefsMember
 * @description Auto-generated from Suma::API::Preferences::PublicPrefsMemberEntity
 * @property {string} email
 * @property {string} name
 * @property {string} phone
 * @property {PublicPrefs} preferences
 */
