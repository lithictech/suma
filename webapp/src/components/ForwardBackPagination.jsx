import { t } from "../localization";
import Pagination from "../ui/Pagination";
import clsx from "clsx";
import { clamp } from "lodash/number";
import React from "react";

export default function ForwardBackPagination({
  page,
  pageCount,
  onPageChange,
  scrollTop,
}) {
  const handlePageChange = (p) => {
    onPageChange(clamp(p, 0, pageCount));
    if (typeof scrollTop !== "undefined") {
      window.scrollTo(0, scrollTop);
    }
  };
  return (
    <Pagination size="md" className="justify-content-end">
      <Pagination.Prev
        className={clsx(page < 1 && "disabled")}
        onClick={() => handlePageChange(page - 1)}
      >
        {t("common.pagination_prev")}
      </Pagination.Prev>
      <Pagination.Next
        className={clsx(page + 1 >= pageCount && "disabled")}
        onClick={() => handlePageChange(page + 1)}
      >
        {t("common.pagination_next")}
      </Pagination.Next>
    </Pagination>
  );
}
