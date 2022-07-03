import "../assets/styles/screenloader.scss";
import TopNav from "../components/TopNav";
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
 * @param {boolean=} options.gutters If true, put this page in a Container/Row/Column,
 *   which provides automatic gutters.
 * @param {boolean=} options.top If true, add an mt-3 to the page content,
 *   to buffer it from the top nav or top of page.
 * @param {string=} options.bg Background color class for the page container.
 */
export default function withLayout(options) {
  options = options || {};
  const nav = options.nav || "top";
  const bg = options.bg || "bg-light";
  const gutterCls = options.gutters ? "px-4" : null;
  const topCls = options.top ? "pt-4" : null;
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
        <div className={bg} style={{ height: "100vh" }}>
          <div className="main-container">
            {nav === "top" && <TopNav />}
            {node}
          </div>
        </div>
      );
    };
  };
}
