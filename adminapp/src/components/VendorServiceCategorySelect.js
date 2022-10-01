import api from "../api";
import { FormControl, FormHelperText, InputLabel, MenuItem, Select } from "@mui/material";
import React from "react";

const VendorServiceCategorySelect = React.forwardRef(function VendorServiceCategorySelect(
  { value, helperText, label, onChange, ...rest },
  ref
) {
  const [categories, setCategories] = React.useState([{ slug: "cash", label: "Cash" }]);

  React.useEffect(() => {
    api.getVendorServiceCategories().then((r) => {
      setCategories(r.data.items);
    });
  }, []);

  function handleChange(e) {
    onChange(e);
  }

  return (
    <FormControl>
      {label && <InputLabel htmlFor="vscategory-select">{label}</InputLabel>}
      <Select
        id="vscategory-select"
        ref={ref}
        value={value}
        label="Category"
        onChange={handleChange}
        {...rest}
      >
        {categories.map(({ label, slug }) => (
          <MenuItem key={slug} value={slug}>
            {label}
          </MenuItem>
        ))}
      </Select>
      {helperText && <FormHelperText>{helperText}</FormHelperText>}
    </FormControl>
  );
});
export default VendorServiceCategorySelect;
