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
import { RouteObject } from "react-router-dom";

export interface RouteProps {
  path: RoutePattern;
  auth?: "require" | "unauthed" | "any";
  onboarded?: "require" | "not" | "any";
  Component: React.ComponentType;
  hocs?: HOC[];
  meta?: MetatagProps | string;
  screenLoader?: boolean;
}

export default function typeRoute({
  path,
  auth = "any",
  onboarded = "any",
  Component,
  hocs,
  meta,
  screenLoader,
}: RouteProps): RouteObject {
  const hocChain: Array<HOC | React.ComponentType<any>> = [];
  if (auth === "require") {
    hocChain.push(redirectIfUnauthed);
  } else if (auth === "unauthed") {
    hocChain.push(redirectIfAuthed);
  }
  if (onboarded === "require") {
    hocChain.push(redirectIfUnboarded);
  } else if (onboarded === "not") {
    hocChain.push(redirectIfBoarded);
  }
  if (isString(meta)) {
    hocChain.push(withMetatags({ title: t(meta) }));
  } else if (meta) {
    hocChain.push(withMetatags(meta));
  }
  if (screenLoader) {
    hocChain.push(withScreenLoaderMount());
  }
  hocChain.push(...(hocs || []));
  hocChain.push(Component);
  const element = renderWithHocs(...hocChain);
  return { path, element };
}

function renderWithHocs(...args: Array<HOC | React.ComponentType<any>>) {
  return renderComponent(applyHocs(...args));
}
