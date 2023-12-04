import { Autocomplete, TextField } from "@mui/material";
import debounce from "lodash/debounce";
import { isObject } from "lodash/lang";
import React from "react";

/**
 * Autocomplete input with search capability.
 *
 * @param {function} search The search function to call with `{q}`.
 *   Each resulting item requires a 'label' and optionally a 'key'.
 * @param {boolean} fullWidth passed to the Autocomplete component.
 * @param {boolean} disabled passed to the Autocomplete component.
 * @param {{label: string}=} value The selected item. If undefined, use an uncontrolled component.
 * @param {function} onValueSelect Called with the selected item (an object returned from the `search` function).
 * @param {string=} text The display value of the text input. If undefined, use an uncontrolled component.
 * @param {boolean=} searchEmpty If true, search when the input is blank.
 *   Otherwise, only search when there are 3 or more characters.
 *   Useful to show a default value on click, but not useful when the number
 *   of possible results is very large.
 * @param {function=} onTextSelect Called with the new display value.
 */
const AutocompleteSearch = React.forwardRef(function AutocompleteSearch(
  {
    search,
    fullWidth,
    disabled,
    value,
    onValueSelect,
    text,
    searchEmpty,
    onTextChange,
    ...rest
  },
  ref
) {
  const activePromise = React.useRef(Promise.resolve());
  const searchDebounced = React.useRef(
    debounce(
      (data) => {
        activePromise.current.cancel();
        activePromise.current = search(data);
        return activePromise.current.then((r) => {
          setOptions(r.data.items);
          hasSearched.current = true;
        });
      },
      150,
      { maxWait: 400 }
    )
  ).current;
  const hasSearched = React.useRef(false);
  const [options, setOptions] = React.useState([]);
  const [emptyOptions, setEmptyOptions] = React.useState([]);

  function handleChange(e) {
    if (!e || e.target.value === 0) {
      // Change is invoked on init (with a null event) and on select (with the value 0, no matter what is selected).
      // I don't understand what this means.
      return;
    }
    activePromise.current.cancel();
    const q = e.target.value || "";
    onTextChange && onTextChange(q);

    if (q.length < 3) {
      setOptions(emptyOptions);
      return;
    }
    searchDebounced({ q });
  }

  function handleSelect(ev, val) {
    // val can be null (which is type object).
    // This will happen when we use the 'clear' button (or delete all text),
    // which calls back a text value change, AND triggers this 'selected' callback.
    // The caller just has to worry about the text change; onValueSelect will never be called with null.
    if (isObject(val)) {
      // If this is in uncontrolled mode, select will be called with a string,
      // even after the selection is made. However we always are dealing with objects,
      // never strings, so never alert if this case is hit.
      onValueSelect(val);
    }
  }

  React.useEffect(() => {
    if (searchEmpty && !hasSearched.current) {
      search().then((r) => {
        setEmptyOptions(r.data.items);
        if (!hasSearched.current) {
          setOptions(r.data.items);
          hasSearched.current = true;
        }
      });
    }
  }, [search, searchEmpty]);

  return (
    <Autocomplete
      freeSolo
      options={options}
      autoHighlight={true}
      selectOnFocus={true}
      value={value || null}
      onChange={handleSelect}
      inputValue={text}
      onInputChange={handleChange}
      filterOptions={(ops) => ops}
      fullWidth={fullWidth}
      disabled={disabled}
      renderInput={(params) => (
        <TextField
          {...params}
          {...rest}
          fullWidth={fullWidth}
          disabled={disabled}
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
