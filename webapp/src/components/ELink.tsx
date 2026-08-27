import ExternalLink from "./ExternalLink";
import { Link, useNavigate } from "react-router-dom";

interface ELinkProps {
  /** Same as `to`. */
  href?: string;
  /** Same as react-router-dom Link#to. */
  to?: string;
  /**
   * If true, navigate directly using onPointerDown,
   * rather than the default behavior of onClick. This allows the caller to bypass
   * things like blur events that happen during form validation.
   * This is only relevant for local URLs.
   */
  immediate?: boolean;
  [rest: string]: any;
}

/**
 * Use this where we don't know if we have an internal or external link.
 *
 * If the link starts with `/` or "#" we use Link,
 * otherwise we use ExternalLink.
 *
 * There are some special behaviors available as well:
 * - If link is local, and includes ##, then replace the current URL.
 * - If the link text includes __blank__ anywhere, then use an external link with target=_blank.
 */
export default function ELink({ href, to, immediate, ...rest }: ELinkProps) {
  const navigate = useNavigate();
  const u = href || to || "";
  if (u.includes("__blank__")) {
    const clean = u.replace("__blank__", "");
    return <ExternalLink href={clean} {...rest} />;
  }
  if (u.startsWith("/") || u.startsWith("#")) {
    let to, replace;
    if (immediate) {
      rest = {
        onPointerDown: () => {
          // We have to use u here, not e.target.attributes.href.value,
          // since href.value already has `/app/<href>` in the built app,
          // which will cause a misnavigate. Instead, use what was passed in.
          // Note this closes over 'to', which may change below.
          navigate(u);
        },
        ...rest,
      };
    }
    if (u.includes("##")) {
      to = u.replace("##", "#");
      replace = true;
    } else {
      to = u;
      replace = u.startsWith("##");
    }
    return <Link to={to} replace={replace} {...rest} />;
  }
  return <ExternalLink href={u} {...rest} />;
}
