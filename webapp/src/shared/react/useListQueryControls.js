import each from "lodash/each";
import has from "lodash/has";
import isUndefined from "lodash/isUndefined";
import { useSearchParams } from "react-router-dom";

export default function useListQueryControls() {
  const [params, setParams] = useSearchParams(new URLSearchParams());
  const page = Number(params.get("page") || "0");
  const perPage = Number(params.get("pagesize") || "50");
  const search = params.get("search");
  const order = params.get("order");
  const orderBy = params.get("orderby");
  function setListQueryParams(arg, more) {
    const sp = new URLSearchParams(params);
    each(urlKeysAndProps, (attr, key) => {
      if (has(arg, attr)) {
        if (isUndefined(arg[attr]) || arg[attr] === "") {
          sp.delete(key);
        } else {
          sp.set(key, "" + arg[attr]);
        }
      }
    });
    each(more, (val, key) => sp.set(key, val));
    setParams(sp);
  }
  return {
    params,
    page,
    perPage,
    search,
    order,
    orderBy,
    setListQueryParams,
  };
}

const urlKeysAndProps = {
  page: "page",
  pagesize: "perPage",
  search: "search",
  order: "order",
  orderby: "orderBy",
};
