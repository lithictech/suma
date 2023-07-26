import isArray from "lodash/isArray";
import mapValues from "lodash/mapValues";
import merge from "lodash/merge";
import React from "react";

/**
 * Render a Suma image entity as an img.
 *
 * @param {{url, caption}} image
 * @param w The 'w' crop parameter.
 * @param h The 'h' crop parameter.
 * @param width The image element width, AND the 'w' crop parameter if `w` is empty.
 * @param height The image element height, AND the 'h' crop parameter if `h` is empty.
 * @param params Additional url params. `{crop: 'lower'}` would send `&crop=lower` for example.
 * @param alt Alt text to use. Overrides image.caption.
 * @param rest Passed to the img tag directly.
 * @returns {JSX.Element}
 * @constructor
 */
export default function SumaImage({ image, w, h, width, height, params, alt, ...rest }) {
  if (!image) {
    return null;
  }

  const defaultPngBackground = "255,255,255";
  params = merge(params, { flatten: defaultPngBackground });
  const cleanParams =
    params && mapValues(params, (v) => (isArray(v) ? v.map((o) => "" + o).join(",") : v));
  const usp = new URLSearchParams(cleanParams || undefined);
  if (w) {
    usp.set("w", w);
  } else if (width) {
    usp.set("w", width);
  }
  if (h) {
    usp.set("h", h);
  } else if (height) {
    usp.set("h", height);
  }
  let src = image.url;
  const q = usp.toString();
  if (q) {
    src += "?" + q;
  }
  return (
    <img
      alt={alt || image.caption || ""}
      src={src}
      height={height}
      width={width}
      {...rest}
    />
  );
}
