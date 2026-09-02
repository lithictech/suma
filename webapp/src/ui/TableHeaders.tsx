import { renderTableCell, TableCell } from "./TableHelpers.tsx";

export interface TableHeadersProps {
  cells: TableCell[];
}
export default function TableHeaders({ cells }: TableHeadersProps) {
  return (
    <thead>
      <tr>{cells.map((c) => renderTableCell(c, "th", { scope: "col" }))}</tr>
    </thead>
  );
}
