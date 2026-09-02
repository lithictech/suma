import relativeUrl from "../modules/relativeUrl";
import setUrlPart from "../modules/setUrlPart";
import trimStart from "lodash/trimStart";
import React from "react";
import { useLocation, useNavigate } from "react-router-dom";

export default function useHashSelector<F extends string, T extends Record<F, string>>(
  items: T[],
  field: F
) {
  const navigate = useNavigate();
  const location = useLocation();
  const [selectedItem, setSelectedItem] = React.useState<T | null>(null);
  React.useEffect(() => {
    if (!location.hash) {
      return;
    }
    const h = trimStart(location.hash, "#");
    const item = items.find((it) => it[field] === h);
    if (!item) {
      return;
    }
    setSelectedItem(item);
  }, [location, items, field]);

  const selectHashItem = React.useCallback(
    (item: T | null) => {
      const hash = item ? item[field] : "#";
      const newLoc = relativeUrl({ location: setUrlPart({ location, hash }) });
      navigate(newLoc, { replace: true });
      setSelectedItem(item);
    },
    [field, location, navigate]
  );

  const onHashItemSelected = React.useCallback(
    (e: React.SyntheticEvent, item: T) => {
      e?.preventDefault();
      selectHashItem(item);
    },
    [selectHashItem]
  );

  return {
    selectedHashItem: selectedItem,
    selectHashItem,
    onHashItemSelected,
  };
}
