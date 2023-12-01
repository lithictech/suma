import useMountEffect from "../shared/react/useMountEffect";
import useScreenLoader from "./useScreenLoader";
import React from "react";

export default function withScreenLoaderMount(show) {
  show = show || false;
  return (Wrapped) => {
    return (props) => {
      const loader = useScreenLoader();
      useMountEffect(() => loader.setState(show));
      return <Wrapped {...props} />;
    };
  };
}
