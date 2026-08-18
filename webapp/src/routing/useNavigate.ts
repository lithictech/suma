import { RoutePath } from "./RoutePath.ts";
import resolveRoutePath from "./resolveRoutePath.ts";
import React from "react";
import { useNavigate as useRNavigate, NavigateOptions } from "react-router-dom";

interface NavigateFunction {
  (to: RoutePath, options?: NavigateOptions): void;
}

export default function useNavigate(): NavigateFunction {
  const rnavigate = useRNavigate();

  return React.useCallback(
    (to: RoutePath, options?: NavigateOptions) => {
      rnavigate(resolveRoutePath(to), options);
    },
    [rnavigate]
  );
}
