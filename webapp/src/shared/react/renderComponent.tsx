import React from "react";

export default function renderComponent(
  Component: React.ElementType,
  props?: Record<string, any>
) {
  return <Component {...(props || {})} />;
}
