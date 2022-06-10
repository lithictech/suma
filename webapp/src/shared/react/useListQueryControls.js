import useQueryParam from "./useQueryParam";
import _ from "lodash";
import React from "react";

export default function useListQueryControls() {
  const [page, setPage] = useQueryParam("page", 1, numberSerializer);
  const [perPage, setPerPage] = useQueryParam("pagesize", 50, numberSerializer);
  const [search, setSearch] = useQueryParam("search", "");
  React.useEffect(() => {
    if (page < 1) {
      setPage(1);
    }
  }, [page, setPage]);
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
