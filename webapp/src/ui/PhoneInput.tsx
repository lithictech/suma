import { maskPhoneNumber } from "../modules/maskPhoneNumber";
import TextInput, { TextInputProps } from "../ui/TextInput.tsx";
import React from "react";

interface PhoneInputProps extends TextInputProps {
  onPhoneChange?: (e: React.ChangeEvent<HTMLInputElement>, formattedNum: string) => void;
}

const PhoneInput = React.forwardRef<HTMLInputElement, PhoneInputProps>(
  function PhoneInput({ onPhoneChange, onChange, ...rest }: PhoneInputProps, ref) {
    function handleChange(e: React.ChangeEvent<HTMLInputElement>) {
      const formattedNum = maskPhoneNumber(e.target.value);
      onChange && onChange(e);
      onPhoneChange && onPhoneChange(e, formattedNum);
    }

    return (
      <TextInput
        ref={ref}
        type="tel"
        name="phone"
        pattern="^(\+\d{1,2}\s)?\(?\d{3}\)?(?:\s|-)\d{3}(?:\s|-)\d{4}$"
        autoComplete="tel"
        onChange={handleChange}
        {...rest}
      />
    );
  }
);
export default PhoneInput;
