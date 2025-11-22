import api from "../api";
import { useGlobalApiState } from "../hooks/globalApiState";
import {
  Box,
  Chip,
  FormControl,
  FormHelperText,
  InputLabel,
  MenuItem,
  OutlinedInput,
  Select,
} from "@mui/material";
import { useTheme } from "@mui/styles";
import React from "react";

/**
 * Set multiple vendor service categories.
 * 'values' and onChange work with category models (objects with an 'id' field).
 * @param {Array<{id: number}>} values
 */
const VendorServiceCategoryMultiSelect = React.forwardRef(
  function VendorServiceCategoryMultiSelect(
    { value, helperText, label, className, style, onChange, ...rest },
    ref
  ) {
    const theme = useTheme();
    const categories = useGlobalApiState(
      api.getVendorServiceCategoriesMeta,
      [{ slug: "cash", label: "Cash" }],
      { pick: (r) => r.data.items }
    );

    const handleChange = React.useCallback(
      (e) => {
        // Since we're dealing with objects, we end up 'adding' a copy when selecting
        // and already selected object. If an id appears multiple times, assume it's due to
        // newly selecting it, and remove it.
        // Alternatively we could manage values as ids, but this keeps all the weirdness in
        // one place so we can deal with real objects elsewhere.
        const values = e.target.value;
        const idCounts = {};
        values.forEach((c) => {
          idCounts[c.id] = (idCounts[c.id] || 0) + 1;
        });
        const nonDupeValues = values.filter((c) => idCounts[c.id] === 1);
        onChange(e, nonDupeValues);
      },
      [onChange]
    );

    return (
      <FormControl className={className} style={style}>
        {label && <InputLabel htmlFor="vscategory-select">{label}</InputLabel>}
        <Select
          id="vscategory-select"
          multiple
          ref={ref}
          value={value}
          label={label}
          input={<OutlinedInput label={label} />}
          renderValue={(selected) => (
            <Box sx={{ display: "flex", flexWrap: "wrap", gap: 0.5 }}>
              {selected.map((c) => (
                <Chip key={c.id} label={c.name} />
              ))}
            </Box>
          )}
          MenuProps={MenuProps}
          onChange={(e) => handleChange(e)}
          {...rest}
        >
          {categories.map((c) => (
            <MenuItem key={c.label} value={c} style={menuItemStyle(c, value, theme)}>
              {c.label}
            </MenuItem>
          ))}
        </Select>
        {helperText && <FormHelperText>{helperText}</FormHelperText>}
      </FormControl>
    );
  }
);
export default VendorServiceCategoryMultiSelect;

const ITEM_HEIGHT = 48;
const ITEM_PADDING_TOP = 8;
const MenuProps = {
  PaperProps: {
    style: {
      maxHeight: ITEM_HEIGHT * 4.5 + ITEM_PADDING_TOP,
      width: 250,
    },
  },
};

function menuItemStyle(c, selected, theme) {
  return {
    fontWeight: selected.some((ca) => ca.id === c.id)
      ? theme.typography.fontWeightMedium
      : theme.typography.fontWeightRegular,
  };
}
