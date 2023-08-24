import api from "../api";
import { FormControl, FormHelperText, InputLabel, MenuItem, Select } from "@mui/material";
import map from "lodash/map";
import React from "react";

const VendorServiceCategorySelect = React.forwardRef(function VendorServiceCategorySelect(
  { value, defaultValue, helperText, label, onChange, ...rest },
  ref
) {
  const [categories, setCategories] = React.useState([{ slug: "cash", label: "Cash" }]);

  const handleChange = React.useCallback(
    (slug) => {
      onChange(slug);
    },
    [onChange]
  );

  React.useEffect(() => {
    api.getVendorServiceCategories().then((r) => {
      setCategories(r.data.items);
      if (map(r.data.items, "slug").includes(defaultValue)) {
        handleChange(defaultValue);
      }
    });
  }, [handleChange, defaultValue]);

  return (
    <FormControl>
      {label && <InputLabel htmlFor="vscategory-select">{label}</InputLabel>}
      <Select
        id="vscategory-select"
        ref={ref}
        value={value}
        label="Category"
        onChange={(e) => handleChange(e.target.value)}
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
