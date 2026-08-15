import "./DialogHeader.css";
import React from "react";

export interface DialogHeaderProps {
  id: string;
  children?: React.ReactNode;
}
export default function DialogHeader({ id, children }: DialogHeaderProps) {
  return (
    <h2 id={id} className="dialog-header">
      {children}
    </h2>
  );
}
