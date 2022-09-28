import _ from "lodash";
import { useSearchParams } from "react-router-dom";

export default function useListQueryControls() {
  const [params, setParams] = useSearchParams(new URLSearchParams());
  const page = Number(params.get("page") || "0");
  const perPage = Number(params.get("pagesize") || "50");
  const search = params.get("search");
  const order = params.get("order");
  const orderBy = params.get("orderby");
  function setListQueryParams(arg) {
    const sp = new URLSearchParams(params);
    _.each(urlKeysAndProps, (attr, key) => {
      if (_.has(arg, attr)) {
        if (_.isUndefined(arg[attr]) || arg[attr] === "") {
          sp.delete(key);
        } else {
          sp.set(key, "" + arg[attr]);
        }
      }
    });
    setParams(sp);
  }
  return {
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
