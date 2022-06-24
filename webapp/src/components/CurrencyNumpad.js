import "./CurrencyNumpad.css";
import _ from "lodash";
import React from "react";
import Keyboard from "react-simple-keyboard";
import "react-simple-keyboard/build/css/index.css";

export default function CurrencyNumpad({ onCentsChange, whole, currency, cents }) {
  const keyboard = React.useRef();

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
      <Keyboard
        keyboardRef={(r) => (keyboard.current = r)}
        layout={{
          default: ["1 2 3", "4 5 6", "7 8 9", "{blank} 0 {bksp}"],
        }}
        display={{
          "{blank}": "",
          "{bksp}": "⌫",
        }}
        theme="hg-theme-default suma"
        onChange={handleChange}
      />
    </div>
  );
}
