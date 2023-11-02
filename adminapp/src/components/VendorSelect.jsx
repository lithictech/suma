import api from "../api";
import { FormControl, FormHelperText, InputLabel, MenuItem, Select } from "@mui/material";
import find from "lodash/find";
import map from "lodash/map";
import React from "react";

const VendorSelect = React.forwardRef(function VendorSelect(
  { value, defaultValue, helperText, label, className, style, onChange, ...rest },
  ref
) {
  const [vendors, setVendors] = React.useState([{ name: "" }]);

  const handleChange = React.useCallback(
    (name) => {
      const newVendor = find(vendors, (c) => c.name === name) || { name };
      onChange(name, newVendor);
    },
    [vendors, onChange]
  );

  React.useEffect(() => {
    api
      .getVendorsMeta()
      .then(api.pickData)
      .then((data) => {
        setVendors(data.items);
      });
  }, []);

  React.useEffect(() => {
    if (map(vendors, "name").includes(defaultValue)) {
      handleChange(defaultValue);
    }
  }, [handleChange, vendors, defaultValue]);

  return (
    <FormControl className={className} style={style}>
      {label && <InputLabel htmlFor="vendor-select">{label}</InputLabel>}
      <Select
        id="vendor-select"
        ref={ref}
        value={value}
        label="Vendor"
        onChange={(e) => handleChange(e.target.value)}
        {...rest}
      >
        {vendors.map(({ name }) => (
          <MenuItem key={name} value={name}>
            {name}
          </MenuItem>
        ))}
      </Select>
      {helperText && <FormHelperText>{helperText}</FormHelperText>}
    </FormControl>
  );
});
export default VendorSelect;
