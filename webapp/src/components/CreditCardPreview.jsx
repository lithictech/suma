import Payment from "../modules/payment.js";
import clsx from "clsx";
import React from "react";

/**
 * Render the credit card preview.
 * @param {PaymentCardInfo} cardInfo
 * @param {string} focused
 * @param {string} name
 * @param {string} placeholderName "YOUR NAME HERE"
 * @param {string} localeValid "valid thru"
 */
export default function CreditCardPreview({
  cardInfo,
  focused,
  name,
  placeholderName,
  localeValid,
}) {
  if (typeof placeholderName !== "string") {
    placeholderName = DEFAULT_PLACEHOLDER_NAME;
  }
  if (typeof localeValid !== "string") {
    localeValid = DEFAULT_VALID_THRU;
  }
  let issuer = cardInfo.cct?.type;
  issuer = ISSUER_RENAMES[issuer] || issuer;
  return (
    <div key="Cards" className="rccs">
      <div
        className={clsx(
          "rccs__card",
          `rccs__card--${issuer}`,
          focused === "cvc" && issuer !== "amex" && "rccs__card--flipped"
        )}
      >
        <div className="rccs__card--front">
          <div className="rccs__card__background" />
          <div className="rccs__issuer" />
          <div className={clsx("rccs__cvc__front", focused === "cvc" && "rccs--focused")}>
            {Payment.formatCardCvc(cardInfo, formatPlaceholder)}
          </div>
          <div
            className={clsx(
              "rccs__number",
              cardInfo.number.replace(/ /g, "").length > 16 && "rccs__number--large",
              focused === "number" && "rccs--focused",
              isFilled(cardInfo.number) && "rccs--filled"
            )}
          >
            {Payment.formatCardNumber(cardInfo, formatPlaceholder)}
          </div>
          <div
            className={clsx(
              "rccs__name",
              focused === "name" && "rccs--focused",
              name && "rccs--filled"
            )}
          >
            {name || placeholderName}
          </div>
          <div
            className={clsx(
              "rccs__expiry",
              focused === "expiry" && "rccs--focused",
              isFilled(cardInfo.expiry) && "rccs--filled"
            )}
          >
            <div className="rccs__expiry__valid">{localeValid}</div>
            <div className="rccs__expiry__value">
              {Payment.formatCardExpiry(cardInfo, formatPlaceholder)}
            </div>
          </div>
          <div className="rccs__chip" />
        </div>
        <div className="rccs__card--back">
          <div className="rccs__card__background" />
          <div className="rccs__stripe" />
          <div className="rccs__signature" />
          <div className={clsx("rccs__cvc", focused === "cvc" && "rccs--focused")}>
            {Payment.formatCardCvc(cardInfo, formatPlaceholder)}
          </div>
          <div className="rccs__issuer" />
        </div>
      </div>
    </div>
  );
}

const ISSUER_RENAMES = {
  "american-express": "amex",
  "diners-club": "diners-club",
};
const DEFAULT_PLACEHOLDER_NAME = "YOUR NAME HERE";
const DEFAULT_VALID_THRU = "valid thru";
const BULLET = "•";
const formatPlaceholder = { placeholder: BULLET };
function isFilled(s) {
  return s[0] !== BULLET;
}
