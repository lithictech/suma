import { renderTableCell, TableCell } from "./TableHelpers.tsx";
import clsx from "clsx";
import { CSSProperties } from "react";

export interface TableRowProps {
  cells: TableCell[];
  highlight?: boolean;
  className?: string;
  style?: CSSProperties;
}
export default function TableRow({ cells, highlight, className, style }: TableRowProps) {
  return (
    <tr className={clsx(highlight && "table-row-highlight", className)} style={style}>
      {cells.map((c) => renderTableCell(c, "td"))}
    </tr>
  );
}
