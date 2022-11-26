import { Logger } from "../logger";
import relativeUrl from "./../relativeUrl";
import setUrlPart from "./../setUrlPart";
import _ from "lodash";
import React from "react";
import { useLocation, useNavigate } from "react-router-dom";

const logger = new Logger("hashselector");

export default function useHashSelector(items, property) {
  if (!property) {
    logger.error("property cannot be empty");
  }
  const navigate = useNavigate();
  const location = useLocation();
  const [selectedItem, setSelectedItem] = React.useState(null);
  React.useEffect(() => {
    if (!location.hash) {
      return;
    }
    const item = _.find(items, { [property]: _.trimStart(location.hash, "#") });
    if (!item) {
      return;
    }
    setSelectedItem(item);
  }, [location, items, property]);

  const onHashItemSelected = React.useCallback(
    (event, item) => {
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
