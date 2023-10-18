import api from "../api";
import { FormControl, FormHelperText, InputLabel, MenuItem, Select } from "@mui/material";
import find from "lodash/find";
import map from "lodash/map";
import React from "react";

const VendorServiceCategorySelect = React.forwardRef(function VendorServiceCategorySelect(
  { value, defaultValue, helperText, label, className, style, onChange, ...rest },
  ref
) {
  const [categories, setCategories] = React.useState([{ slug: "cash", label: "Cash" }]);

  const handleChange = React.useCallback(
    (slug) => {
      const newCategory = find(categories, (c) => c.slug === slug) || { slug };
      onChange(slug, newCategory);
    },
    [categories, onChange]
  );

  React.useEffect(() => {
    api.getVendorServiceCategories().then((r) => {
      setCategories(r.data.items);
    });
  }, []);

  React.useEffect(() => {
    if (map(categories, "slug").includes(defaultValue)) {
      handleChange(defaultValue);
    }
  }, [handleChange, categories, defaultValue]);

  return (
    <FormControl className={className} style={style}>
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
