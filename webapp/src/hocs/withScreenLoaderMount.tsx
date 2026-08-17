import useMountEffect from "../state/useMountEffect";
import useScreenLoader from "../state/useScreenLoader";
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
