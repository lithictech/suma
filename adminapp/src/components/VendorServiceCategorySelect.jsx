import api from "../api";
import { useGlobalApiState } from "../hooks/globalApiState";
import { FormControl, FormHelperText, InputLabel, MenuItem, Select } from "@mui/material";
import find from "lodash/find";
import map from "lodash/map";
import React from "react";

const VendorServiceCategorySelect = React.forwardRef(function VendorServiceCategorySelect(
  { value, defaultValue, helperText, label, className, style, onChange, ...rest },
  ref
) {
  const categories = useGlobalApiState(
    api.getVendorServiceCategories,
    [{ slug: "cash", label: "Cash" }],
    { pick: (r) => r.data.items }
  );

  const handleChange = React.useCallback(
    (slug) => {
      const newCategory = find(categories, (c) => c.slug === slug) || { slug };
      onChange(slug, newCategory);
    },
    [categories, onChange]
  );

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
        {categories.map(({ name, slug }) => (
          <MenuItem key={slug} value={slug}>
            {name}
          </MenuItem>
        ))}
      </Select>
      {helperText && <FormHelperText>{helperText}</FormHelperText>}
    </FormControl>
  );
});
export default VendorServiceCategorySelect;
