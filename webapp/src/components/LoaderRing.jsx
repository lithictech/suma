import loaderRingStatic from "../assets/images/loader-ring-static.svg";
import loaderRing from "../assets/images/loader-ring.svg";
import React from "react";

/**
 * The loading ring image. The ring spins through an animation inside the SVG,
 * which CSS cannot stop, so users who ask for reduced motion get a still
 * version of the same image instead (WCAG 2.3.3 Animation from Interactions).
 * All props are passed to the img element.
 */
export default function LoaderRing(props) {
  return (
    <picture>
      <source media="(prefers-reduced-motion: reduce)" srcSet={loaderRingStatic} />
      <img src={loaderRing} alt="" aria-hidden="true" {...props} />
    </picture>
  );
}
