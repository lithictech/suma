import React from "react";

export default function withProps(props: Record<string, any>) {
  return (Wrapped: React.ComponentType<any>) => (innerProps: any) =>
    <Wrapped {...innerProps} {...props} />;
}
