import useQueryParam from "./useQueryParam";
import _ from "lodash";

export default function useListQueryControls() {
  const [page, setPage] = useQueryParam(window.location, "page", 0, numberSerializer);
  const [perPage, setPerPage] = useQueryParam(
    window.location,
    "pagesize",
    50,
    numberSerializer
  );
  const [search, setSearch] = useQueryParam(window.location, "search", "");
  return {
    page,
    setPage,
    perPage,
    setPerPage,
    search,
    setSearch,
  };
}

const numberSerializer = { parse: Number, serialize: _.toString };
