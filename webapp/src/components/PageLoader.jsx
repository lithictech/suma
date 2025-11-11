import loaderRing from "../assets/images/loader-ring.svg";
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
 * @param {string} containerClass
 * @param {string} className
 * @param {number=} height
 * @param {number=} width
 * @returns {JSX.Element}
 */
export default function PageLoader({
  overlay,
  buffered,
  width,
  height,
  containerClass,
  className,
}) {
  const cls = clsx(
    overlay && "position-absolute top-0 start-50 translate-middle-x",
    buffered && "my-5",
    className
  );
  return (
    <div className={clsx("text-center", containerClass)}>
      <img
        src={loaderRing}
        width={width}
        height={height}
        alt=""
        className={cls}
        style={{ maxWidth: 150 }}
      />
    </div>
  );
}
