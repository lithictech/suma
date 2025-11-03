import React from "react";

export default function DrawerContents({ children }) {
  return <div className="d-flex flex-column gap-2">{children}</div>;
}
