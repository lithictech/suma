import {
  redirectIfAuthed,
  redirectIfBoarded,
  redirectIfUnauthed,
  redirectIfUnboarded,
} from "../hocs/authRedirects.tsx";
import { HOC } from "../hocs/hocs.ts";
import withMetatags, { MetatagProps } from "../hocs/withMetatags.tsx";
import withScreenLoaderMount from "../hocs/withScreenLoaderMount.tsx";
import { t } from "../localization";
import applyHocs from "../modules/applyHocs.ts";
import renderComponent from "../uir/renderComponent.tsx";
import { RoutePattern } from "./RoutePath.ts";
import isString from "lodash/isString";
import React from "react";
import { Route as RRoute } from "react-router-dom";

export interface RouteProps {
  path: RoutePattern;
  auth?: "require" | "unauthed" | "any";
  onboarded?: "require" | "not" | "any";
  Component: React.ComponentType;
  hocs?: HOC[];
  meta?: MetatagProps | string;
  screenLoader?: boolean;
}

export default function Route({
  path,
  auth = "any",
  onboarded = "any",
  Component,
  hocs,
  meta,
  screenLoader,
}: RouteProps) {
  const hocChain = React.useMemo(() => {
    const chain = [];
    if (auth === "require") {
      chain.push(redirectIfUnauthed);
    } else if (auth === "unauthed") {
      chain.push(redirectIfAuthed);
    }
    if (onboarded === "require") {
      chain.push(redirectIfUnboarded);
    } else if (onboarded === "not") {
      chain.push(redirectIfBoarded);
    }
    return chain;
  }, [auth, onboarded]);
  if (isString(meta)) {
    hocChain.push(withMetatags({ title: t(meta) }));
  } else if (meta) {
    hocChain.push(withMetatags(meta));
  }
  if (screenLoader) {
    hocChain.push(withScreenLoaderMount());
  }
  hocChain.concat(hocs || []);
  hocChain.push(Component);
  return <RRoute path={path} element={renderWithHocs(...hocChain)} />;
}

function renderWithHocs(...args: Array<(x: any) => any>) {
  return renderComponent(applyHocs(...args));
}
