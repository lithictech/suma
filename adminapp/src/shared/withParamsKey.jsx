import React from "react";
import { useParams } from "react-router";

export default function withParamsKey(...attrs) {
  return (Wrapped) => {
    return (props) => {
      const params = useParams();
      const key = "" + attrs.map((a) => params[a]);
      React.useEffect(() => window.scrollTo(0, 0), [key]);
      return <Wrapped {...props} key={key} />;
    };
  };
}
