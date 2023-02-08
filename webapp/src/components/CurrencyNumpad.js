import _ from "lodash";
import React from "react";
import Button from "react-bootstrap/Button";

export default function CurrencyNumpad({ onCentsChange, whole, currency, cents }) {
  if (!whole) {
    throw new Error("whole must be true for now!");
  }

  const handleChange = (x) => {
    onCentsChange(Number(x) * currency.centsInDollar);
  };

  return (
    <div>
      <div className="display-4 mb-3 ms-3 me-3 d-flex flex-row justify-content-end">
        <div>{currency.symbol}</div>
        <div className="text-end" style={{ minWidth: 60 }}>
          {_.isNumber(cents) && cents / currency.centsInDollar}
        </div>
      </div>
      <Numpad cents={cents} currency={currency} onNumberClick={handleChange} />
    </div>
  );
}

function Numpad({ cents, currency, onNumberClick }) {
  const handleNumberClick = (e) => {
    if (Number(e.target.value) === 0) {
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
        <Button variant="light" className={numButtonClasses} onClick={handleNumberDelete}>
          ⌫
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

const numButtonClasses = "numpad-number-button mb-1";
