import api from "../api";
import AutocompleteSearch from "./AutocompleteSearch";
import React from "react";

/**
 * Supports multiple language text fields.
 * This component supports English and Spanish but could change in the future,
 * for example adding additional TextFields for the multiple languages
 * @returns {JSX.Element}
 */
const MultiLingualText = React.forwardRef(function MultiLingualText(
  { value, label, searchParams, onChange, ...rest },
  ref
) {
  const handleSelect = (t) => {
    onChange({ en: t.en, es: t.es });
  };
  searchParams = searchParams || {};
  const doSearch = React.useCallback(
    (language, seachArg) => {
      const param = { language, ...searchParams, ...seachArg };
      return api.searchTranslations(param);
    },
    [searchParams]
  );
  return (
    <>
      <AutocompleteSearch
        {...rest}
        label={`English ${label}`}
        search={(o) => doSearch("en", o)}
        value={value.en}
        onValueSelect={handleSelect}
      />
      <AutocompleteSearch
        {...rest}
        label={`Spanish ${label}`}
        search={(o) => doSearch("es", o)}
        value={value.es}
        onValueSelect={handleSelect}
      />
    </>
  );
});
export default MultiLingualText;
