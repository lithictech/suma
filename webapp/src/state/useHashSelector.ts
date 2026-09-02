import React from "react";

export default function useHashSelector<F extends string, T extends Record<F, string>>(
  items: T[],
  field: F
) {
  const [selectedId, setSelectedId] = React.useState<string | null>(
    () => window.location.hash.slice(1) || null // read once, on mount
  );
  const selectedHashItem = items.find((it) => it[field] === selectedId);

  const selectHashItem = React.useCallback(
    (item: T | null) => {
      const hash = item ? `#${item[field]}` : "";
      window.history.replaceState(
        null,
        "",
        hash || window.location.pathname + window.location.search
      );
      setSelectedId(item ? item[field] : null);
    },
    [field]
  );

  React.useEffect(() => {
    const onHashChange = () => setSelectedId(window.location.hash.slice(1) || null);
    window.addEventListener("hashchange", onHashChange);
    return () => window.removeEventListener("hashchange", onHashChange);
  }, []);

  const onHashItemSelected = React.useCallback(
    (e: React.SyntheticEvent, item: T) => {
      e.preventDefault();
      selectHashItem(item);
    },
    [selectHashItem]
  );

  return {
    selectedHashItem,
    selectHashItem,
    onHashItemSelected,
  };
}
