import React from "react";

export type HTMLTableCellProps = React.DetailedHTMLProps<
  React.TdHTMLAttributes<HTMLTableCellElement>,
  HTMLTableCellElement
>;

export type TableCell = string | React.ReactElement | HTMLTableCellProps;

export function renderTableCell(
  c: TableCell,
  elementType: string,
  more?: HTMLTableCellProps
) {
  const tblElement = asTableElement(c);
  if (tblElement) {
    return tblElement;
  }
  let cellProps: HTMLTableCellProps = { ...more };
  let key;
  if (typeof c === "string" || React.isValidElement(c)) {
    cellProps = { ...cellProps, children: c };
    key = "" + c;
  } else {
    cellProps = { ...cellProps, ...c };
    key = "" + cellProps;
  }
  const C = elementType;
  return <C key={key} {...cellProps} />;
}

function asTableElement(c: TableCell) {
  if (!React.isValidElement(c)) {
    return null;
  }
  const e: React.ReactElement = c;
  const et: any = e.type;
  const t = et.displayName ?? et.name ?? "";
  if (t.startsWith("Table") || TABLE_TYPES[t]) {
    return e;
  }
  return null;
}

const TABLE_TYPES: Record<string, boolean> = {
  thead: true,
  tbody: true,
  th: true,
  tr: true,
  td: true,
};
