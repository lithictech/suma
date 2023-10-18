import React from "react";

export default function withProps(props) {
  return (Wrapped) => (innerProps) => <Wrapped {...innerProps} {...props} />;
}
