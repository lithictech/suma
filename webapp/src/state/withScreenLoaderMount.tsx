import useMountEffect from "../shared/react/useMountEffect";
import useScreenLoader from "./useScreenLoader";
import React from "react";

export default function withScreenLoaderMount(show?: boolean) {
  show = show || false;
  return (Wrapped: React.ComponentType<any>) => {
    return (props: any) => {
      const loader = useScreenLoader();
      useMountEffect(() => loader.setState(show));
      return <Wrapped {...props} />;
    };
  };
}
