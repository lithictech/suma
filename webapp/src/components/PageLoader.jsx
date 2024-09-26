import loaderRing from "../assets/images/loader-ring.svg";
import { t } from "../localization";
import clsx from "clsx";
import React from "react";

/**
 * Render the page loader icon centered.
 * This is used when you are loading information and want to
 * display the default loading ring icon as a child while
 * the information loads or an API request completes
 * (ie, `if (dataLoading) return <PageLoader />`).
 *
 * If using the PageLoader to overlay existing content,
 * pass `overlay`. It will absolutely position the div so it
 * overlays whatever is in the same container.
 *
 * If using the PageLoader on an otherwise empty screen
 * (the common case), pass `buffered`, which will apply
 * a top margin to give the loader a more natural vertical
 * placement.
 * @param {boolean} buffered
 * @param {boolean} overlay
 * @param {string} className
 * @returns {JSX.Element}
 */
export default function PageLoader({ overlay, buffered, className }) {
  const cls = clsx(
    overlay && "position-absolute top-0 start-50 translate-middle-x",
    buffered && "my-5",
    className
  );
  return (
    <div className={clsx("text-center")}>
      <img
        src={loaderRing}
        alt={t("common:loading_icon")}
        className={cls}
        style={{ maxWidth: 150 }}
      />
    </div>
  );
}
