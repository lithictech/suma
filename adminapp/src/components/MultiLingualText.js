import { TextField } from "@mui/material";
import React from "react";

/**
 * Supports multiple language text fields.
 * This component supports English and Spanish but could change in the future,
 * for example adding additional TextFields for the multiple languages
 * @returns {JSX.Element}
 */
export default function MultiLingualText({ value, label, onChange, disabled, ...rest }) {
  const { en, es } = value || { en: "", es: "" };
  const handleOnChange = (val, language) => {
    let newValue = value;
    newValue[language] = val ? val : "";
    onChange(newValue);
  };
  return (
    <>
      <TextField
        {...rest}
        title={en}
        defaultValue={en}
        label={`English ${label}`}
        onChange={(e) => handleOnChange(e.target.value, "en")}
        disabled={disabled && Boolean(en)}
      />
      <TextField
        {...rest}
        title={es}
        defaultValue={es}
        label={`Spanish ${label}`}
        onChange={(e) => handleOnChange(e.target.value, "es")}
        disabled={disabled && Boolean(es)}
      />
    </>
  );
}
