import React from "react";

function Br() {
  return <br />;
}

export default function elementJoin(arr, Sep = Br) {
  if (!arr || !arr.length) {
    return null;
  }
  const result = [];
  arr.forEach((el, i) => {
    result.push(el);
    result.push(<Sep key={i} />);
  });
  result.pop();
  return result;
}
