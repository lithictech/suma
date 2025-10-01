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
      onChange={handleChange}
      {...rest}
    />
  );
}
