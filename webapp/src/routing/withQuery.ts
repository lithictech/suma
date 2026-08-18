import { RouteParams } from "./RouteParams.ts";
import { EmptyParams, PlainRoutePath } from "./RoutePath.ts";
import { RouteQuery } from "./RouteQuery.ts";

export class RoutePathWithQuery {
  path: PlainRoutePath;
  query: Record<string, string | number | boolean | undefined>;
  constructor(path: PlainRoutePath, query: RoutePathWithQuery["query"]) {
    this.path = path;
    this.query = query;
  }
}

type QueryFor<K> = K extends keyof RouteQuery ? RouteQuery[K] : never;

export function withQuery<K extends keyof RouteQuery>(
  path: K extends keyof RouteParams
    ? RouteParams[K] extends EmptyParams
      ? K
      : [K, RouteParams[K]]
    : never,
  query: QueryFor<K>
): RoutePathWithQuery {
  return new RoutePathWithQuery(path, query);
}
