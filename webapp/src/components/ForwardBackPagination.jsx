import { t } from "../localization";
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
    onPageChange(clamp(p, 0, pageCount));
    if (typeof scrollTop !== "undefined") {
      window.scrollTo(0, scrollTop);
    }
  };
  return (
    <Pagination size="md" className="justify-content-end">
      <Pagination.Prev disabled={page < 1} onClick={() => handlePageChange(page - 1)}>
        {t("common.pagination_prev")}
      </Pagination.Prev>
      <Pagination.Next
        disabled={page + 1 >= pageCount}
        onClick={() => handlePageChange(page + 1)}
      >
        {t("common.pagination_next")}
      </Pagination.Next>
    </Pagination>
  );
}
