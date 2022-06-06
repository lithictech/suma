import TopNav from "../components/TopNav";
import React from "react";
import Button from "react-bootstrap/Button";

const Styleguide = () => {
  return (
    <div className="main-container">
      <TopNav />
      <h1>H1 Heading</h1>
      <h2>H2 Heading</h2>
      <h3>H3 Heading</h3>
      <h4>H4 Heading</h4>
      <h5>H5 Heading</h5>
      <h6>H6 Heading</h6>
      <p>Paragraph text</p>
      <p className="lead">Lead Text</p>
      <hr />
      {["sm", undefined, "lg"].map((size) => {
        const variants = [
          "primary",
          "secondary",
          "success",
          "danger",
          "warning",
          "info",
          "dark",
          "light",
          "link",
          "outline-primary",
          "outline-secondary",
          "outline-success",
          "outline-danger",
          "outline-warning",
          "outline-info",
          "outline-dark",
          "outline-light",
        ];
        return (
          <div key={size}>
            {variants.map((v) => (
              <Button key={v} variant={v} size={size} className="m-1">
                {v}
              </Button>
            ))}
          </div>
        );
      })}
    </div>
  );
};

export default Styleguide;
