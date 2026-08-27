import { t } from "../localization";
import "./SumaImage.css";
import styles from "./SumaImage.module.css";
import clsx from "clsx";
import isArray from "lodash/isArray";
import mapValues from "lodash/mapValues";
import React from "react";

interface SumaImageProps {
  image?: Image;
  /** The 'w' crop parameter. */
  w?: number | string;
  /** The 'h' crop parameter. */
  h?: number | string;
  /** The image element width, AND the 'w' crop parameter if `w` is empty. */
  width?: number | string;
  /** The image element height, AND the 'h' crop parameter if `h` is empty. */
  height?: number | string;
  /** Height for the placeholder/error elements. Defaults to height. */
  placeholderHeight?: number | string;
  /** Additional url params. `{crop: 'lower'}` would send `&crop=lower` for example. */
  params?: Record<string, any>;
  /** Alt text to use. Overrides image.caption. */
  alt?: string;
  /** If true, "fill" the image to the given height.
   * Uses a width of 100%, given height, and object-fit: cover.
   */
  cover?: boolean;
  className?: string;
  style?: React.CSSProperties;
}

/**
 * Render a Suma image entity as an img.
 * Either 'width' or 'height' must be passed in
 * to size the actual image (or placeholder/error) elements.
 * Without either of these passed in, the layout would jump when
 * the image loads, and the placeholder/error elements could not be shown at all.
 */
export default function SumaImage({
  image,
  w,
  h,
  width,
  height,
  placeholderHeight,
  params,
  alt,
  cover,
  className,
  style,
  ...rest
}: SumaImageProps) {
  placeholderHeight = placeholderHeight || height;
  if (!width && !placeholderHeight) {
    console.warn(
      "SumaImage: 'height', 'placeholderHeight', or 'width' required to use loader and error placeholders."
    );
  }
  const [loaded, setLoaded] = React.useState(false);
  const [errored, setErrored] = React.useState(false);

  if (!image) {
    return null;
  }

  const realAlt = alt || image.caption || "";

  const cleanParams =
    params && mapValues(params, (v) => (isArray(v) ? v.map((o) => "" + o).join(",") : v));
  const usp = new URLSearchParams(cleanParams || undefined);
  if (w) {
    usp.set("w", w as string);
  } else if (width) {
    usp.set("w", width as string);
  }
  if (h) {
    usp.set("h", h as string);
  } else if (height) {
    usp.set("h", height as string);
  }

  let src = image.url;
  const q = usp.toString();
  if (q) {
    src += "?" + q;
  }
  const sty: React.CSSProperties = { ...style };
  if (height && width) {
    // There isn't a case we can think of where we explicitly want a width and height,
    // but then want to allow shrinking the image, because it would result in
    // the image getting squished. Instead, we would use an explicit width OR height.
    sty.minWidth = width;
    sty.minHeight = height;
  }
  if (errored) {
    sty.width = width || "100%";
    sty.height = placeholderHeight || h;
    const smallError = Number(width || w) < 120;
    return (
      <div
        className={clsx(styles.error, smallError && styles["error-small"], className)}
        style={sty}
      >
        {"☹"} {realAlt || t("errors.image_load_failed")}
      </div>
    );
  }
  return (
    <>
      {!loaded && (
        <div
          className={clsx(styles.loader, className)}
          style={{ ...sty, height: placeholderHeight || h, width: width || "100%" }}
        />
      )}
      <img
        alt={realAlt}
        src={src}
        height={height}
        width={width}
        className={clsx(!loaded && styles.hidden, cover && styles.cover, className)}
        style={sty}
        onError={() => setErrored(true)}
        onLoad={() => setLoaded(true)}
        {...rest}
      />
    </>
  );
}
