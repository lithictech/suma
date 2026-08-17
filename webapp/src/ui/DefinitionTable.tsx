import "./DefinitionTable.css";
import React from "react";

interface KeyValueItem {
  label: string;
  value: React.ReactNode;
}
interface KeyValueProps {
  items: KeyValueItem[];
}

export default function DefinitionTable({ items }: KeyValueProps) {
  return (
    <dl className="definition-table">
      {items.map(({ label, value }) => (
        <div key={label + value}>
          <dt className="definition-table-key">{label}</dt>
          <dd className="definition-table-value">{value}</dd>
        </div>
      ))}
    </dl>
  );
}
