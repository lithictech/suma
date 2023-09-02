import api from "../api";
import { FormControl, FormHelperText, InputLabel, MenuItem, Select } from "@mui/material";
import first from "lodash/first";
import get from "lodash/get";
import map from "lodash/map";
import React from "react";

const VendorServiceCategorySelect = React.forwardRef(function VendorServiceCategorySelect(
  {
    value,
    defaultValue,
    helperText,
    label,
    className,
    style,
    onChange,
    disabled,
    ...rest
  },
  ref
) {
  const [categories, setCategories] = React.useState([{ slug: "cash", label: "Cash" }]);
  const selectedCategoryLabel = get(
    categories.find(({ label, slug }) => slug === value && label.toString()),
    "label",
    value
  );
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

  const title = rest.title || selectedCategoryLabel;
  return (
    <FormControl className={className} style={style}>
      {label && <InputLabel htmlFor="vscategory-select">{label}</InputLabel>}
      <Select
        id="vscategory-select"
        ref={ref}
        title={title}
        value={value}
        label="Category"
        disabled={disabled && Boolean(defaultValue)}
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
