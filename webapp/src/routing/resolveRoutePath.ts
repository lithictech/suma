import { RoutePath, UntypedRoutePath } from "./RoutePath.ts";
import { RoutePathWithQuery } from "./withQuery.ts";

export default function resolveRoutePath(path: RoutePath): string {
  if (path instanceof UntypedRoutePath) {
    return path.path;
  } else if (path instanceof RoutePathWithQuery) {
    const sp = new URLSearchParams();
    Object.entries(path.query).forEach(([k, v]) => {
      if (v === null || v === undefined) {
        return;
      }
      sp.set(k, "" + v);
    });
    const root = resolveRoutePath(path.path);
    if (!sp.size) {
      return root;
    }
    return `${root}?${sp.toString()}`;
  }
  if (!Array.isArray(path)) {
    return path;
  }
  const [pattern, params] = path;
  let pth: string = pattern;
  Object.entries(params as Record<string, unknown>).forEach(([k, v]) => {
    pth = pth.replace(`:${k}`, String(v));
  });
  return pth;
}
