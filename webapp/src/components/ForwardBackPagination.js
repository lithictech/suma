import clsx from "clsx";
import i18next from "i18next";
import { clamp } from "lodash/number";
import React from "react";
import Pagination from "react-bootstrap/Pagination";

export default function ForwardBackPagination({
  page,
  pageCount,
  onPageChange,
  scrollTop,
}) {
  const handlePageChange = (p) => {
    onPageChange(clamp(p, 1, pageCount));
    if (typeof scrollTop !== "undefined") {
      window.scrollTo(0, scrollTop);
    }
  };
  return (
    <Pagination size="sm" className="justify-content-end">
      <Pagination.Prev
        className={clsx(page <= 1 && "disabled")}
        onClick={() => handlePageChange(page - 1)}
      >
        {i18next.t("common:pagination_prev")}
      </Pagination.Prev>
      <Pagination.Next
        className={clsx(page >= pageCount && "disabled")}
        onClick={() => handlePageChange(page + 1)}
      >
        {i18next.t("common:pagination_next")}
      </Pagination.Next>
    </Pagination>
  );
}
