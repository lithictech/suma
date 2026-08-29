import { t } from "../localization";
import Pagination from "../ui/Pagination";
import PaginationNext from "../ui/PaginationNext";
import PaginationPrev from "../ui/PaginationPrev";
import clsx from "clsx";
import { clamp } from "lodash/number";

interface ForwardBackPaginationProps {
  page: number;
  pageCount: number;
  onPageChange: (page: number) => void;
  scrollTop?: number;
}

export default function ForwardBackPagination({
  page,
  pageCount,
  onPageChange,
  scrollTop,
}: ForwardBackPaginationProps) {
  const handlePageChange = (p: number) => {
    onPageChange(clamp(p, 0, pageCount));
    if (typeof scrollTop !== "undefined") {
      window.scrollTo(0, scrollTop);
    }
  };
  return (
    <Pagination className="justify-content-end">
      <PaginationPrev
        className={clsx(page < 1 && "disabled")}
        onClick={() => handlePageChange(page - 1)}
      >
        {t("common.pagination_prev")}
      </PaginationPrev>
      <PaginationNext
        className={clsx(page + 1 >= pageCount && "disabled")}
        onClick={() => handlePageChange(page + 1)}
      >
        {t("common.pagination_next")}
      </PaginationNext>
    </Pagination>
  );
}
