import loaderRing from "../assets/images/loader-ring.svg";
import clsx from "clsx";
import React from "react";

/**
 * Render the screen loader overlay.
 * For async work, use the `useScreenLoader` hook.
 * This is used when there is some async dependency
 * a screen has, and you want to render an overlay loader
 * while the page loads (ie, `return <ScreenLoader show />`).
 * @param show
 * @returns {JSX.Element}
 */
export default function ScreenLoader({ show }) {
  return (
    <div
      className={clsx(
        "screen-loader",
        show ? "screen-loader-show" : "screen-loader-hide"
      )}
    >
      <div className="screen-loader-centerer">
        <img src={loaderRing} alt="loading" />
      </div>
    </div>
  );
}
