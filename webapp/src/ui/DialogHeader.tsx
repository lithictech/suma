import "./DialogHeader.css";
import React from "react";

export default function DialogHeader({ children }: { children?: React.ReactNode }) {
  return <h2 className="dialog-header">{children}</h2>;
}
