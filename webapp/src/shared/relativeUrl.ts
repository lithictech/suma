import toUrl, { LocationLike } from "./toUrl";

export default function relativeUrl({ location }: { location: LocationLike }): string {
  const url = toUrl(location);
  const schemIdx = url.href.indexOf("://");
  const hostLen = url.host.length;
  return url.href.slice(schemIdx + hostLen + 3); // 3 is length of ://
}
