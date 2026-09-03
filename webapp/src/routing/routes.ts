/* eslint-disable @typescript-eslint/no-empty-object-type */
declare module "./RouteParams.ts" {
  interface RouteParams {
    "/": {};
    "/*": {};
    "/privacy-policy": {};
    "/privacy-policy-content": {};
    "/terms-of-use": {};
    "/start": {};
    "/regain-account-access": {};
    "/regain-account-access/success": {};
    "/one-time-password": {};
    "/partner-signup": {};
    "/onboarding": {};
    "/onboarding/theme": {};
    "/onboarding/name": {};
    "/onboarding/address": {};
    "/onboarding/eligibility": {};
    "/onboarding/offers": {};
    "/contact-list": {};
    "/contact-list/add": {};
    "/contact-list/success": {};
    "/dashboard": {};
    "/menu": {};
    "/mobility": {};
    "/food": {};
    "/food/:id": { id: string | number };
    "/product/:offeringId/:productId": {
      offeringId: string | number;
      productId: string | number;
    };
    "/cart/:id": { id: string | number };
    "/checkout/:id": { id: string | number };
    "/checkout/:id/confirmation": { id: string | number };
    "/utilities": {};
    "/funding": {};
    "/link-bank-account": {};
    "/add-card": {};
    "/add-funds": {};
    "/ledgers": {};
    "/order-history": {};
    "/unclaimed-orders": {};
    "/order/:id": { id: string | number };
    "/private-accounts": {};
    "/private-account/:id": { id: string | number };
    "/sitemap": {};
    "/theme": {};
    "/trips": {};
    "/trip/:id": { id: string | number };
    "/preferences": {};
    "/preferences-public": {};
    "/error": {};
  }
}
declare module "./RouteQuery.ts" {
  interface RouteQuery {
    "/contact-list/add": { eventName?: string | null };
    "/contact-list": { eventName?: string | null };
    "/add-card": { returnTo?: string | null; returnToImmediate?: string | null };
    "/add-funds": { id?: string | number | null; paymentMethodType?: string | null };
    "/trip/:id": { trip: string };
  }
}

/* eslint-enable */

export {};
