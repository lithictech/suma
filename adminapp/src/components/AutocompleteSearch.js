import { Autocomplete, TextField } from "@mui/material";
import debounce from "lodash/debounce";
import React from "react";

const AutocompleteSearch = React.forwardRef(function AutocompleteSearch(
  { search, fullWidth, onValueSelect, defaultValue, ...rest },
  ref
) {
  const activePromise = React.useRef(Promise.resolve());
  const searchDebounced = React.useRef(
    debounce(
      (data) => {
        activePromise.current.cancel();
        activePromise.current = search(data);
        return activePromise.current.then((r) => setOptions(r.data.items));
      },
      150,
      { maxWait: 400 }
    )
  ).current;
  const [options, setOptions] = React.useState([]);

  function handleChange(e) {
    activePromise.current.cancel();
    const q = e.target.value;
    if (q.length < 3) {
      setOptions([]);
      return;
    }
    searchDebounced({ q });
  }
  function handleSelect(ev, val) {
    onValueSelect(val);
  }

  return (
    <Autocomplete
      freeSolo
      options={options}
      autoHighlight={true}
      autoSelect={true}
      selectOnFocus={true}
      value={defaultValue}
      onChange={handleSelect}
      fullWidth={fullWidth}
      renderInput={(params) => (
        <TextField
          {...params}
          {...rest}
          fullWidth={fullWidth}
          onChange={handleChange}
          InputProps={{
            ...params.InputProps,
            type: "search",
          }}
        />
      )}
      renderOption={(params, o) => (
        <li {...params} key={o.key || o.label}>
          {o.label}
        </li>
      )}
    />
  );
});
export default AutocompleteSearch;
