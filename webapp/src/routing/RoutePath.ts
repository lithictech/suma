import { RouteParams } from "./RouteParams.ts";
import { RoutePathWithQuery } from "./withQuery.ts";

export type EmptyParams = Record<string, never>;

export type RoutePath =
  | {
      [K in keyof RouteParams]: RouteParams[K] extends EmptyParams
        ? K
        : [K, RouteParams[K]];
    }[keyof RouteParams]
  | RoutePathWithQuery
  | UntypedRoutePath;

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
