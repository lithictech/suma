import clsx from "clsx";
import i18next from "i18next";
import React from "react";
import Pagination from "react-bootstrap/Pagination";

export default function ForwardBackPagination({ page, pageCount, onPageChange }) {
  return (
    <Pagination size="sm" className="justify-content-end">
      <Pagination.Prev
        className={clsx(page <= 0 && "disabled")}
        onClick={(_e) => onPageChange(page - 1)}
      >
        {i18next.t("pagination_prev", { ns: "common" })}
      </Pagination.Prev>
      <Pagination.Next
        className={clsx(page + 1 >= pageCount && "disabled")}
        onClick={(_e) => onPageChange(page + 1)}
      >
        {i18next.t("pagination_next", { ns: "common" })}
      </Pagination.Next>
    </Pagination>
  );
}
