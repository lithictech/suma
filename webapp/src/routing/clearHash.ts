import { Location, NavigateFunction } from "react-router";

export default function clearHash(location: Location, navigate: NavigateFunction) {
  navigate(
    { pathname: location.pathname, search: location.search, hash: "" },
    { replace: true }
  );
}
