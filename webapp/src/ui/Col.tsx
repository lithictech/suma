import React from "react";

export default function Col(params: React.HTMLAttributes<HTMLDivElement>) {
  return <div className="col" {...params} />;
}
