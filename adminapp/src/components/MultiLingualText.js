import { TextField } from "@mui/material";
import React from "react";

/**
 * Supports multiple language text fields.
 * This component supports English and Spanish but could change in the future,
 * for example adding additional TextFields for the multiple languages
 * @returns {JSX.Element}
 */
export default function MultiLingualText({ value, label, onChange, ...rest }) {
  const handleOnChange = (val, language) => {
    // There should always be an English translation
    let newValue = value || { en: "" };
    newValue[language] = val ? val : "";
    onChange(newValue);
  };
  return (
    <>
      <TextField
        {...rest}
        label={`English ${label}`}
        onChange={(e) => handleOnChange(e.target.value, "en")}
      />
      <TextField
        {...rest}
        label={`Spanish ${label}`}
        onChange={(e) => handleOnChange(e.target.value, "es")}
      />
    </>
  );
}
