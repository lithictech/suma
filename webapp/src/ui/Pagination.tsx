import { ButtonSize, ButtonVariant } from "./Button.tsx";
import IconButton from "./IconButton.tsx";
import "./Pagination.css";
import Stack from "./Stack.tsx";
import clsx from "clsx";
import { CSSProperties } from "react";

export interface PaginationProps {
  page: number;
  pageCount: number;
  onPageChange: (pg: number) => void;
  variant?: ButtonVariant;
  size?: ButtonSize;
  className?: string;
  style?: CSSProperties;
}
export default function Pagination({
  page,
  pageCount,
  onPageChange,
  variant = "outline",
  size,
  className,
  style,
}: PaginationProps) {
  const isFirstPage = page === 0;
  const isLastPage = page === pageCount - 1;
  return (
    <div className={clsx("pagination", className)} style={style}>
      <Stack row>
        <IconButton
          icon="left"
          variant={variant}
          size={size}
          disabled={isFirstPage}
          title={isFirstPage ? "" : `View Page ${page - 1}`}
          onClick={() => onPageChange(page - 1)}
          className={clsx("pagination-back")}
        />
        <div
          className={clsx(
            "pagination-divider",
            pageCount === 1 && "pagination-divider-disabled"
          )}
        />
        <IconButton
          icon="right"
          variant={variant}
          size={size}
          disabled={isLastPage}
          title={isLastPage ? "" : `View Page ${page + 1}`}
          onClick={() => onPageChange(page + 1)}
          className={clsx("pagination-forward")}
        />
      </Stack>
    </div>
  );
}
