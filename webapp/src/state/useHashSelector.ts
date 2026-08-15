import { Logger } from "../shared/logger";
import relativeUrl from "../shared/relativeUrl";
import setUrlPart from "../shared/setUrlPart";
import find from "lodash/find";
import trimStart from "lodash/trimStart";
import React from "react";
import { useLocation, useNavigate } from "react-router-dom";

const logger = new Logger("hashselector");

export default function useHashSelector(items: any[], property: string) {
  if (!property) {
    logger.error("property cannot be empty");
  }
  const navigate = useNavigate();
  const location = useLocation();
  const [selectedItem, setSelectedItem] = React.useState<any>(null);
  React.useEffect(() => {
    if (!location.hash) {
      return;
    }
    const item = find(items, { [property]: trimStart(location.hash, "#") });
    if (!item) {
      return;
    }
    setSelectedItem(item);
  }, [location, items, property]);

  const onHashItemSelected = React.useCallback(
    (event: { preventDefault: () => void } | undefined, item: any) => {
      event && event.preventDefault();
      const hash = item ? item[property] : "#";
      navigate(relativeUrl({ location: setUrlPart({ location, hash }) }), {
        replace: true,
      });
      setSelectedItem(item);
    },
    [location, navigate, property]
  );

  return {
    selectedHashItem: selectedItem,
    onHashItemSelected,
  };
}
