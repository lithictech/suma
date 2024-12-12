import { t } from "../localization";
import styles from "./SumaImage.module.css";
import clsx from "clsx";
import isArray from "lodash/isArray";
import mapValues from "lodash/mapValues";
import React from "react";

/**
 * Render a Suma image entity as an img.
 * Either 'width' or 'height' must be passed in
 * to size the actual image (or placeholder/error) elements.
 * Without either of these passed in, the layout would jump when
 * the image loads, and the placeholder/error elements could not be shown at all.
 *
 * @param {{url, caption}} image
 * @param w The 'w' crop parameter.
 * @param h The 'h' crop parameter.
 * @param width The image element width, AND the 'w' crop parameter if `w` is empty.
 * @param height The image element height, AND the 'h' crop parameter if `h` is empty.
 * @param params Additional url params. `{crop: 'lower'}` would send `&crop=lower` for example.
 * @param alt Alt text to use. Overrides image.caption.
 * @param {'light'|'dark'} variant Version to use (use 'light' on a dark background, etc). Default to 'light'.
 * @param className
 * @param {object=} style
 * @param rest Passed to the img tag directly.
 * @returns {JSX.Element}
 * @constructor
 */
export default function SumaImage({
  image,
  w,
  h,
  width,
  height,
  params,
  alt,
  variant,
  className,
  style,
  ...rest
}) {
  if (!width && !height) {
    console.warn(
      "SumaImage: 'height' or 'width' required to use loader and error placeholders."
    );
  }
  const [loaded, setLoaded] = React.useState(false);
  const [errored, setErrored] = React.useState(false);

  if (!image) {
    return null;
  }

  const realAlt = alt || image.caption || "";
  variant = variant || "light";

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
  const sty = { ...style };
  if (height && width) {
    // There isn't a case we can think of where we explicitly want a width and height,
    // but then want to allow shrinking the image, because it would result in
    // the image getting squished. Instead we would use an explicit width OR height.
    sty.minWidth = width;
    sty.minHeight = height;
  }
  if (errored) {
    sty.width = width || "100%";
    sty.height = height || h;
    const smallError = (width || w) < 120;
    return (
      <div
        className={clsx(styles.error, smallError && styles["error-small"], className)}
        style={sty}
      >
        {"\u2639"} {realAlt || t("errors:image_load_failed")}
      </div>
    );
  }
  return (
    <>
      {!loaded && (
        <div
          className={clsx(styles.loader, styles[`loader-${variant}`], className)}
          style={{ ...sty, height: height || h, width: width || "100%" }}
        />
      )}
      <img
        alt={realAlt}
        src={src}
        height={height}
        width={width}
        className={clsx(!loaded && styles.hidden, className)}
        style={sty}
        onError={() => setErrored(true)}
        onLoad={() => setLoaded(true)}
        {...rest}
      />
    </>
  );
}
