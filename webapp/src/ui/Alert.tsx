import React from "react";

export default function Alert(params: React.HTMLAttributes<HTMLDivElement>) {
  return <div className="alert" {...params} />;
}
