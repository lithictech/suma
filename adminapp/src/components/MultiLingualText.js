import { FormHelperText, Stack, TextField } from "@mui/material";
import React from "react";

/**
 * Supports multiple language text fields.
 * This component supports English and Spanish but could change in the future,
 * for example adding additional TextFields for the multiple languages
 * @returns {JSX.Element}
 */
const MultiLingualText = React.forwardRef(function MultiLingualText(
  { value, label, helperText, onChange, ...rest },
  ref
) {
  const handleOnChange = (val, language) => {
    // There should always be an English memo translation
    let memo = value || { en: "" };
    memo[language] = val ? val : "";
    onChange(memo);
  };
  return (
    <Stack alignItems="stretch" gap={2}>
      <TextField
        {...rest}
        label={`En ${label}`}
        onChange={(e) => handleOnChange(e.target.value, "en")}
      />
      <div>
        <TextField
          {...rest}
          label={`Es ${label}`}
          onChange={(e) => handleOnChange(e.target.value, "es")}
        />
        <FormHelperText>{helperText}</FormHelperText>
      </div>
    </Stack>
  );
});

export default MultiLingualText;
