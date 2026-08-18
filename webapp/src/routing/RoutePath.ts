import { RouteParams } from "./RouteParams.ts";
import { RoutePathWithQuery } from "./withQuery.ts";

export type EmptyParams = Record<string, never>;

/** A path with its params resolved (or no params), not wrapped by withQuery/untypedRoutePath. */
export type PlainRoutePath = {
  [K in keyof RouteParams]: RouteParams[K] extends EmptyParams ? K : [K, RouteParams[K]];
}[keyof RouteParams];

export type RoutePath = PlainRoutePath | RoutePathWithQuery | UntypedRoutePath;

/** The bare path pattern for a route definition (eg. "/food/:id"), with no params value. */
export type RoutePattern = keyof RouteParams;

export class UntypedRoutePath {
  path: string;

  constructor(path: string) {
    this.path = path;
  }
}

export function untypedRoutePath(path: string): UntypedRoutePath {
  return new UntypedRoutePath(path);
}
