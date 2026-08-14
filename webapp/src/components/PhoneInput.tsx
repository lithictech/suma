import { maskPhoneNumber } from "../modules/maskPhoneNumber";
import FormControlGroup from "./FormControlGroup";
import React from "react";
import { FieldValues, UseFormRegister } from "react-hook-form";

interface PhoneInputProps {
  onPhoneChange?: (e: React.ChangeEvent<HTMLInputElement>, formattedNum: string) => void;
  onChange?: (e: React.ChangeEvent<HTMLInputElement>) => void;
  register: UseFormRegister<FieldValues>;
  [rest: string]: any;
}

export default function PhoneInput({
  onPhoneChange,
  onChange,
  ...rest
}: PhoneInputProps) {
  function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
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
