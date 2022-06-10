import loaderRing from "../assets/images/loader-ring.svg";
import React from "react";

/**
 * Render the page loader icon centered.
 * This is used when you are loading information and want to
 * display the default loading ring icon as a child while
 * the information loads (ie, `return <PageLoader show />`).
 * @param show
 * @returns {JSX.Element}
 */
export default function PageLoader({ show }) {
  if (!show) {
    return null;
  }
  return (
    <div className="text-center">
      <img src={loaderRing} alt="loading" />
    </div>
  );
}
