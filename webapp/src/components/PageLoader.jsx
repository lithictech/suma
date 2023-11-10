import loaderRing from "../assets/images/loader-ring.svg";
import clsx from "clsx";
import React from "react";

/**
 * Render the page loader icon centered.
 * This is used when you are loading information and want to
 * display the default loading ring icon as a child while
 * the information loads (ie, `return <PageLoader relative />`).
 * @param relative
 * @returns {JSX.Element}
 */
export default function PageLoader({ relative }) {
  const cls = clsx(
    relative
      ? "position-relative top-0 start-0"
      : "position-absolute start-50 translate-middle-x",
    "page-loader-img my-5"
  );
  return (
    <div className="text-center position-relative">
      <img src={loaderRing} alt="loading" className={cls} />
    </div>
  );
}
