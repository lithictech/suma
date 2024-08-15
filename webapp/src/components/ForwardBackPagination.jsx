import { t } from "../localization";
import clsx from "clsx";
import { clamp } from "lodash/number";
import React from "react";
import Pagination from "react-bootstrap/Pagination";

/**
 * Right-aligned Forward and back buttons for pagination,
 * includes page information. The page number displayed is 1-based
 * for user readability but note that query param controllers may
 * be 0-based.
 * @param {number} page current page
 * @param {number} pageCount max page count
 * @param {boolean} hasMorePages has next page available
 * @param {function} onPageChange callback func that passes new page number
 * @param {number} scrollTop value to scroll up to (from top of window)
 * @returns {JSX.Element}
 * @constructor
 */
export default function ForwardBackPagination({
  page,
  pageCount,
  hasMorePages,
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
    <div className="d-flex align-items-center justify-content-end gap-3">
      <p>
        Page {page} of {pageCount}
      </p>
      <Pagination size="md">
        <Pagination.Prev
          className={clsx(page <= 1 && "disabled")}
          onClick={() => handlePageChange(page - 2)}
        >
          {t("common:pagination_prev")}
        </Pagination.Prev>
        <Pagination.Next
          className={clsx(!hasMorePages && "disabled")}
          onClick={() => handlePageChange(page)}
        >
          {t("common:pagination_next")}
        </Pagination.Next>
      </Pagination>
    </div>
  );
}
