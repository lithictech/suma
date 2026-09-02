import "./ForwardBackPagination.css";
import { page } from "@vitest/browser/context";

export interface ForwardBackPaginationProps {
  page: number;
  pageCount: number;
  onPageChange: (pg: number) => void;
}
export default function ForwardBackPagination({ page }: ForwardBackPaginationProps) {
  return null;
}
