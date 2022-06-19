import "./CurrencyNumpad.css";
import Money, { intToMoney } from "./Money";
import _ from "lodash";
import React from "react";
import Keyboard from "react-simple-keyboard";
import "react-simple-keyboard/build/css/index.css";

export default function CurrencyNumpad({ onCentsChange, whole, currency, cents }) {
  const keyboard = React.useRef();

  if (!whole) {
    throw new Error("whole must be true for now!");
  }

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
          default: ["1 2 3", "4 5 6", "7 8 9", "{bksp} {0} {blank}"],
        }}
        display={{
          "{1}": "1&nbsp;",
          "{2}": "2&nbsp;",
          "{3}": "3&nbsp;",
          "{4}": "4&nbsp;",
          "{5}": "5&nbsp;",
          "{6}": "6&nbsp;",
          "{7}": "7&nbsp;",
          "{8}": "8&nbsp;",
          "{9}": "9&nbsp;",
          "{bksp}": "⌫",
          "{0}": "0&nbsp;&nbsp;",
          "{blank}": "&nbsp;&nbsp;&nbsp;&nbsp;",
        }}
        theme="hg-theme-default suma"
        buttonTheme={[
          {
            class: "hg-hidden",
            buttons: "{blank}",
          },
        ]}
        onChange={(x) => onCentsChange(Number(x) * currency.centsInDollar)}
      />
    </div>
  );
}
