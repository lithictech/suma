import { renderTableCell, TableCell } from "./TableHelpers.tsx";

export interface TableRowProps {
  cells: TableCell[];
}
export default function TableRow({ cells }: TableRowProps) {
  return <tr>{cells.map((c) => renderTableCell(c, "td"))}</tr>;
}
