import { t } from "../localization";
import FormText from "./FormText";
import clsx from "clsx";
import isNumber from "lodash/isNumber";
import React from "react";
import Button from "react-bootstrap/Button";

/**
 * @param {function} onCentsChange
 * @param {boolean} whole
 * @param {object} currency
 * @param {number} cents
 * @param {string|JSX.Element=} helpText Help shown under the amount,
 *   like the minimum and maximum allowed.
 */
export default function CurrencyNumpad({
  onCentsChange,
  whole,
  currency,
  cents,
  helpText,
}) {
  if (!whole) {
    throw new Error("whole must be true for now!");
  }

  const handleChange = (x) => {
    onCentsChange(Number(x) * currency.centsInDollar);
  };

  return (
    <div>
      <output
        aria-live="polite"
        aria-label={t("forms.amount")}
        aria-describedby={helpText ? HELP_TEXT_ID : undefined}
        className={clsx(
          "display-4 ms-3 me-3 d-flex flex-row justify-content-end",
          helpText ? "mb-1" : "mb-3"
        )}
      >
        <div>{currency.symbol}</div>
        <div className="text-end" style={{ minWidth: 60 }}>
          {isNumber(cents) && cents / currency.centsInDollar}
        </div>
      </output>
      {helpText && (
        <FormText id={HELP_TEXT_ID} className="text-end mt-0 mb-3 ms-3 me-3">
          {helpText}
        </FormText>
      )}
      <Numpad cents={cents} currency={currency} onNumberClick={handleChange} />
    </div>
  );
}

function Numpad({ cents, currency, onNumberClick }) {
  const handleNumberClick = (e) => {
    if (Number(cents) === 0 && Number(e.target.value) === 0) {
      return;
    }
    onNumberClick(Number(cents / currency.centsInDollar) + e.target.value);
  };

  const handleNumberDelete = () => {
    if (Number(cents) === 0) {
      return;
    }
    onNumberClick(
      Number(cents / currency.centsInDollar)
        .toString()
        .slice(0, -1)
    );
  };
  return (
    <div className="text-align-center">
      <RenderButtons numbers={[1, 2, 3]} handleChange={handleNumberClick} />
      <RenderButtons numbers={[4, 5, 6]} handleChange={handleNumberClick} />
      <RenderButtons numbers={[7, 8, 9]} handleChange={handleNumberClick} />
      <div className="d-flex justify-content-end">
        <Button
          variant="light"
          className={numButtonClasses}
          value={0}
          onClick={handleNumberClick}
        >
          0
        </Button>
        <Button
          variant="light"
          className={numButtonClasses}
          aria-label={t("forms.delete_digit")}
          onClick={handleNumberDelete}
        >
          <span aria-hidden="true">⌫</span>
        </Button>
      </div>
    </div>
  );
}

function RenderButtons({ numbers, handleChange }) {
  return (
    <div className="d-flex justify-content-between">
      {numbers.map((num) => (
        <Button
          key={num}
          variant="light"
          className={numButtonClasses}
          value={num}
          onClick={handleChange}
        >
          {num}
        </Button>
      ))}
    </div>
  );
}

const HELP_TEXT_ID = "currency-numpad-help";

const numButtonClasses = "numpad-number-button mb-1";
