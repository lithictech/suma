import { maskPhoneNumber } from "../modules/maskPhoneNumber";
import FormControlGroup from "./FormControlGroup";
import React from "react";

export default function PhoneInput({ onPhoneChange, onChange, ...rest }) {
  function handleChange(e) {
    const formattedNum = maskPhoneNumber(e.target.value);
    onChange && onChange(e);
    onPhoneChange && onPhoneChange(e, formattedNum);
  }

  return (
    <FormControlGroup
      type="tel"
      name="phone"
      pattern="^(\+\d{1,2}\s)?\(?\d{3}\)?[\s-]\d{3}[\s-]\d{4}$"
      autoComplete="tel"
      // An empty phone field gets the same message as an invalid one,
      // so it says what to enter, not only that something is missing (3.3.3).
      errorKeys={{ required: "forms.invalid_phone", pattern: "forms.invalid_phone" }}
      onChange={handleChange}
      {...rest}
    />
  );
}
