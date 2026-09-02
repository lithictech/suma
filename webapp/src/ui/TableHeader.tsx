import { HTMLTableCellProps } from "./TableHelpers.tsx";

export interface TableHeaderProps extends HTMLTableCellProps {
  row?: boolean;
}

export default function TableHeader({ row, ...rest }: TableHeaderProps) {
  return <th scope={row ? "row" : "col"} {...rest} />;
}
