import Button from "../ui/Button";
import isNumber from "lodash/isNumber";
import React from "react";

interface CurrencyNumpadProps {
  onCentsChange: (cents: number) => void;
  whole: boolean;
  currency: Currency;
  cents?: number;
}

export default function CurrencyNumpad({
  onCentsChange,
  whole,
  currency,
  cents,
}: CurrencyNumpadProps) {
  if (!whole) {
    throw new Error("whole must be true for now!");
  }

  const handleChange = (x: string | number) => {
    onCentsChange(Number(x) * currency.centsInDollar);
  };

  return (
    <div>
      <div className="display-4 mb-3 ms-3 me-3 d-flex flex-row justify-content-end">
        <div>{currency.symbol}</div>
        <div className="text-end" style={{ minWidth: 60 }}>
          {isNumber(cents) && cents / currency.centsInDollar}
        </div>
      </div>
      <Numpad cents={cents} currency={currency} onNumberClick={handleChange} />
    </div>
  );
}

interface NumpadProps {
  cents?: number;
  currency: Currency;
  onNumberClick: (x: string | number) => void;
}

function Numpad({ cents, currency, onNumberClick }: NumpadProps) {
  const handleNumberClick = (e: React.MouseEvent<HTMLButtonElement>) => {
    const value = (e.target as HTMLButtonElement).value;
    if (Number(cents) === 0 && Number(value) === 0) {
      return;
    }
    onNumberClick(Number(Number(cents) / currency.centsInDollar) + value);
  };

  const handleNumberDelete = () => {
    if (Number(cents) === 0) {
      return;
    }
    onNumberClick(
      Number(Number(cents) / currency.centsInDollar)
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

interface RenderButtonsProps {
  numbers: number[];
  handleChange: (e: React.MouseEvent<HTMLButtonElement>) => void;
}

function RenderButtons({ numbers, handleChange }: RenderButtonsProps) {
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
