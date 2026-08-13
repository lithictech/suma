import PageLoader from "../components/PageLoader";
import Button from "../ui/Button";
import Chip from "../ui/Chip.jsx";
import Container from "../ui/Container";
import ProgressBar from "../ui/ProgressBar.jsx";
import Stack from "../ui/Stack";
import React from "react";

export default function Styleguide() {
  const keys = ["typography", "buttons", "chips", "misc", "loaders"];
  const [activeKey, setActiveKey] = React.useState(
    window.location.hash.substring(1) || keys[0]
  );
  function changeKey(k) {
    setActiveKey(k);
    window.location.hash = k;
  }
  return (
    <Container className="mt-2">
      <Stack direction="horizontal" gap={2}>
        {keys.map((k) => (
          <Button
            key={k}
            variant={k === activeKey ? `primary` : "text"}
            onClick={() => changeKey(k)}
          >
            {k[0].toUpperCase() + k.substring(1)}
          </Button>
        ))}
      </Stack>
      <hr />
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
        <Stack direction="vertical" gap={3}>
          {BUTTON_PROPS.map((props) => (
            <Stack key={JSON.stringify(props)} gap={2}>
              {BUTTON_STATES.map((st) => (
                <Button key={st} className={st} {...props}></Button>
              ))}
            </Stack>
          ))}
        </Stack>
      </Section>
      <Section eventKey="chips" activeKey={activeKey}>
        <Stack gap={2}>
          <Chip variant="secondary">Available now</Chip>
          <Chip variant="info">Ready for pickup</Chip>
          <Chip variant="danger">2 left</Chip>
          <Chip variant="success">Picked up</Chip>
        </Stack>
      </Section>
      <Section eventKey="misc" activeKey={activeKey}>
        <Stack direction="vertical" gap={1}>
          <h2>Progress</h2>
          <ProgressBar value={0} />
          <ProgressBar value={37} />
          <ProgressBar value={50} />
          <ProgressBar value={96} />
          <ProgressBar value={100} />
        </Stack>
      </Section>
      <Section eventKey="loaders" activeKey={activeKey}>
        <PageLoader buffered />
        <hr />
        <div className="position-relative">
          <p>{LOREM_IPSUM}</p>
          <PageLoader overlay />
        </div>
      </Section>
    </Container>
  );
}

const BUTTON_PROPS = [
  { children: "Continue", variant: "primary" },
  { children: "Back", variant: "secondary" },
  { children: "Skip for now", variant: "text" },
  { children: "Add", variant: "outline", size: "sm" },
  { children: "Large Btn", size: "lg" },
];

const BUTTON_STATES = ["", "is-hover", "is-focus-visible", "is-disabled"];

function Section({ eventKey, activeKey, children }) {
  if (eventKey !== activeKey) {
    return null;
  }
  return <div className="mt-2 mx-2">{children}</div>;
}

const LOREM_IPSUM = `Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras sed ligula
blandit, dictum massa quis, lobortis metus. Nunc ac justo nec ante tincidunt
euismod ut vel libero. Sed gravida porta malesuada. Sed iaculis pretium urna
vel elementum. Sed vel egestas nisi, eget molestie diam. Vivamus urna elit,
elementum ut justo et, cursus interdum tortor. Proin suscipit ac neque sit
amet iaculis. In ut erat in mauris feugiat ornare. Sed condimentum non enim ut
lacinia. Fusce ac libero cursus magna vulputate rutrum. Nullam dapibus enim eu
facilisis cursus. Mauris vel est a lacus venenatis sollicitudin et eget
turpis. Lorem ipsum dolor sit amet, consectetur adipiscing elit. Nunc at
viverra tellus. Nunc vitae nulla nisl.`;
