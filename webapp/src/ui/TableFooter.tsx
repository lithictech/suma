import { renderTableCell, TableCell } from "./TableHelpers.tsx";

export interface TableFooterProps {
  cells: TableCell[];
}
export default function TableFooter({ cells }: TableFooterProps) {
  return (
    <tfoot>
      <tr>{cells.map((c) => renderTableCell(c, "td"))}</tr>
    </tfoot>
  );
}
