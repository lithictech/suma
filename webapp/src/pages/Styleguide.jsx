import PageLoader from "../components/PageLoader";
import React from "react";
import Button from "react-bootstrap/Button";
import Nav from "react-bootstrap/Nav";

export default function Styleguide() {
  const [activeKey, setActiveKey] = React.useState("typography");
  return (
    <div className="mt-2">
      <Nav variant="tabs" activeKey={activeKey} onSelect={(v) => setActiveKey(v)}>
        <Nav.Item>
          <Nav.Link eventKey="typography">Typography</Nav.Link>
        </Nav.Item>
        <Nav.Item>
          <Nav.Link eventKey="buttons">Buttons</Nav.Link>
        </Nav.Item>
        <Nav.Item>
          <Nav.Link eventKey="loaders">Loaders</Nav.Link>
        </Nav.Item>
      </Nav>
      <Section eventKey="typography" activeKey={activeKey}>
        <h1>H1 Heading</h1>
        <h2>H2 Heading</h2>
        <h3>H3 Heading</h3>
        <h4>H4 Heading</h4>
        <h5>H5 Heading</h5>
        <h6>H6 Heading</h6>
        <p>Paragraph text</p>
        <p className="lead">Lead Text</p>
      </Section>
      <Section eventKey="buttons" activeKey={activeKey}>
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
      </Section>
      <Section eventKey="loaders" activeKey={activeKey}>
        <PageLoader buffered />
        <hr />
        <div className="position-relative">
          <p>
            Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras sed ligula
            blandit, dictum massa quis, lobortis metus. Nunc ac justo nec ante tincidunt
            euismod ut vel libero. Sed gravida porta malesuada. Sed iaculis pretium urna
            vel elementum. Sed vel egestas nisi, eget molestie diam. Vivamus urna elit,
            elementum ut justo et, cursus interdum tortor. Proin suscipit ac neque sit
            amet iaculis. In ut erat in mauris feugiat ornare. Sed condimentum non enim ut
            lacinia. Fusce ac libero cursus magna vulputate rutrum. Nullam dapibus enim eu
            facilisis cursus. Mauris vel est a lacus venenatis sollicitudin et eget
            turpis. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc at
            viverra tellus. Nunc vitae nulla nisl.
          </p>
          <PageLoader overlay />
        </div>
      </Section>
    </div>
  );
}

function Section({ eventKey, activeKey, children }) {
  if (eventKey !== activeKey) {
    return null;
  }
  return <div className="mt-2 mx-2">{children}</div>;
}
