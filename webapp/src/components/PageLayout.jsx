import AppNav from "../components/AppNav";
import TopNav from "../components/TopNav";
import { guttersClass, topMarginClass } from "../modules/constants";
import ScrollTopOnMount from "../shared/ScrollToTopOnMount";
import clsx from "clsx";
import React from "react";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";

/**
 * Configure the layout associated with the page.
 * Note that this puts the content into an outer div which
 * gives the given background color to the entire page.
 *
 * There should be only one of these, often set in App.jsx,
 * but it can be set in the page component if dynamic content is needed
 * (usually adding another sticky element to the nav).
 *
 * @param {string=} nav 'top' or 'none'
 * @param {boolean=} appNav If true, display appNav below topNav
 * @param {boolean=} gutters If true, put this page in a Container/Row/Column,
 *   which provides automatic gutters.
 * @param {boolean=} top If true, add an mt-3 to the page content,
 *   to buffer it from the top nav or top of page.
 * @param {boolean=} noBottom By default, we add a bottom padding to every page,
 *   so the page content doesn't sit at the bottom of the screen.
 *   In rare cases (like the mobility map), we want the page content to sit flush
 *   with the bottom. Use noBottom in those cases.
 * @param {boolean=} noScrollTop By default, scroll to top when the page mounts.
 * @param {string=} bg Background color class for the page container.
 * @param children
 */
export default function PageLayout({
  nav,
  appNav,
  gutters,
  top,
  noBottom,
  noScrollTop,
  bg,
  children,
}) {
  nav = nav || "top";
  const hasNav = nav !== "none" || appNav;
  bg = bg || "bg-light";
  const gutterCls = gutters ? guttersClass : null;
  const topCls = top ? topMarginClass : null;
  const noBottomCls = noBottom ? null : "pb-5";
  const scrollTop = !noScrollTop;
  let node;
  if (gutterCls) {
    node = (
      <Container className={clsx(topCls, gutterCls)}>
        <Row>
          <Col>{children}</Col>
        </Row>
      </Container>
    );
  } else if (topCls) {
    node = <div className={topCls}>{children}</div>;
  } else {
    node = children;
  }
  return (
    <div className={clsx(bg, "root", noBottomCls)}>
      {scrollTop && <ScrollTopOnMount />}
      <div className="main-container">
        {hasNav && (
          <div className="sticky-top">
            {nav === "top" && <TopNav />}
            {appNav === true && <AppNav />}
          </div>
        )}
        {node}
      </div>
    </div>
  );
}
