import "../assets/styles/screenloader.scss";
import AppNav from "../components/AppNav";
import TopNav from "../components/TopNav";
import ScrollTopOnMount from "../shared/ScrollToTopOnMount";
import clsx from "clsx";
import React from "react";
import Col from "react-bootstrap/Col";
import Container from "react-bootstrap/Container";
import Row from "react-bootstrap/Row";

/**
 * Choose the layout associated with the page.
 * Note that this puts the content into an outer div which
 * gives the given background color to the entire page.
 *
 * @param {object=} options
 * @param {string=} options.nav 'top' or 'none'
 * @param {boolean=} options.appNav If true, display appNav below topNav
 * @param {boolean=} options.gutters If true, put this page in a Container/Row/Column,
 *   which provides automatic gutters.
 * @param {boolean=} options.top If true, add an mt-3 to the page content,
 *   to buffer it from the top nav or top of page.
 * @param {boolean=} options.noBottom By default, we add a bottom padding to every page,
 *   so the page content doesn't sit at the bottom of the screen.
 *   In rare cases (like the mobility map), we want the page content to sit flush
 *   with the bottom. Use noBottom in those cases.
 * @param {boolean=} options.noScrollTop By default, scroll to top when the page mounts.
 * @param {string=} options.bg Background color class for the page container.
 */
export default function withLayout(options) {
  options = options || {};
  const nav = options.nav || "top";
  const appNav = options.appNav;
  const hasNav = nav !== "none" || options.navApp;
  const bg = options.bg || "bg-light";
  const gutterCls = options.gutters ? guttersClass : null;
  const topCls = options.top ? topMarginClass : null;
  const noBottomCls = options.noBottom ? null : "pb-5";
  const scrollTop = !options.noScrollTop;
  return (Wrapped) => {
    return (props) => {
      let node;
      if (gutterCls) {
        node = (
          <Container className={clsx(topCls, gutterCls)}>
            <Row>
              <Col>
                <Wrapped {...props} />
              </Col>
            </Row>
          </Container>
        );
      } else if (topCls) {
        node = (
          <div className={topCls}>
            <Wrapped {...props} />
          </div>
        );
      } else {
        node = <Wrapped {...props} />;
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
    };
  };
}

export const topMarginClass = "pt-4";
export const guttersClass = "px-4";

export function LayoutContainer({ className, gutters, top, ...rest }) {
  const cls = clsx(top && topMarginClass, gutters && guttersClass, className);
  return (
    <Container className={cls} {...rest}/>
  );
}
