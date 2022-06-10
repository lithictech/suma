import useQueryParam from "./useQueryParam";
import _ from "lodash";

export default function useListQueryControls() {
  const [page, setPage] = useQueryParam("page", 0, numberSerializer);
  const [perPage, setPerPage] = useQueryParam("pagesize", 50, numberSerializer);
  const [search, setSearch] = useQueryParam("search", "");
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
