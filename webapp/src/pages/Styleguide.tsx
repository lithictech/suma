import useToggle from "../state/useToggle";
import BrandCard from "../ui/BrandCard";
import Button from "../ui/Button";
import ButtonGroup from "../ui/ButtonGroup";
import Card from "../ui/Card";
import CardBody from "../ui/CardBody";
import CardText from "../ui/CardText";
import CheckableCard from "../ui/CheckableCard";
import Checkbox from "../ui/Checkbox";
import { CheckboxCard } from "../ui/CheckboxCard";
import Checklist from "../ui/Checklist";
import ChecklistItem from "../ui/ChecklistItem";
import Chip from "../ui/Chip";
import Container from "../ui/Container";
import { Dialog } from "../ui/Dialog";
import DialogHeader from "../ui/DialogHeader";
import IndeterminateLoader from "../ui/IndeterminateLoader";
import Nav from "../ui/Nav";
import NavOption from "../ui/NavOption";
import Progress from "../ui/Progress";
import Select from "../ui/Select";
import Stack from "../ui/Stack";
import Switch from "../ui/Switch";
import SwitchRow from "../ui/SwitchRow";
import TextInput from "../ui/TextInput";
import Tile from "../ui/Tile";
import BuildingStorefrontIcon from "@heroicons/react/24/outline/BuildingStorefrontIcon";
import HomeIcon from "@heroicons/react/24/outline/HomeIcon";
import ShoppingCartIcon from "@heroicons/react/24/outline/ShoppingCartIcon";
import SquaresPlusIcon from "@heroicons/react/24/outline/SquaresPlusIcon";
import noop from "lodash/noop";
import React from "react";

export default function Styleguide() {
  const keys = [
    "typography",
    "buttons",
    "cards",
    "chips",
    "inputs",
    "checklist",
    "progress",
    "nav",
    "dialogs",
    "loaders",
  ];
  const [activeKey, setActiveKey] = React.useState(
    window.location.hash.substring(1) || keys[0]
  );
  const dialogToggle = useToggle();
  function changeKey(k: string) {
    setActiveKey(k);
    window.location.hash = k;
  }
  const dialogFocusRef = React.useRef(null);
  return (
    <Container className="mt-2">
      <Stack direction="horizontal" gap={2} wrap>
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
        <p>{LOREM_IPSUM}</p>
      </Section>
      <Section eventKey="buttons" activeKey={activeKey}>
        <Stack direction="vertical" gap={3}>
          <h2>Buttons</h2>
          {BUTTON_PROPS.map((props) => (
            <Stack key={JSON.stringify(props)} gap={2}>
              {BUTTON_STATES.map((st) => (
                <Button
                  key={st}
                  className={st}
                  disabled={st === "is-disabled"}
                  {...props}
                ></Button>
              ))}
            </Stack>
          ))}
          <h2>Link Buttons</h2>
          {BUTTON_PROPS.map((props) => (
            <Stack key={JSON.stringify(props)} gap={2} wrap>
              {BUTTON_STATES.map((st) => (
                <Button
                  key={st}
                  className={st}
                  disabled={st === "is-disabled"}
                  {...props}
                  to="#"
                />
              ))}
            </Stack>
          ))}
        </Stack>
      </Section>
      <Section eventKey="cards" activeKey={activeKey}>
        <Stack gap={2} direction="vertical">
          <Card>
            <CardBody>
              <CardText variant="title">Your savings so far</CardText>
              <CardText>Across every offer you have used</CardText>
            </CardBody>
          </Card>
          <CheckableCard checked onChange={noop}>
            <CardBody>
              <CardText>This card is checked.</CardText>
            </CardBody>
          </CheckableCard>
          <CheckableCard checked={false} onChange={noop}>
            <CardBody>
              <CardText>This card is unchecked.</CardText>
            </CardBody>
          </CheckableCard>
          <CheckableCard checked={false} className="is-focus-visible" onChange={noop}>
            <CardBody>
              <CardText>This card has focus.</CardText>
            </CardBody>
          </CheckableCard>
          <CheckableCard checked={false} disabled onChange={noop}>
            <CardBody>
              <CardText>This card is disabled.</CardText>
            </CardBody>
          </CheckableCard>
          <Stack gap={3}>
            <CheckableCard checked={false} onChange={noop} style={{ maxWidth: 150 }}>
              <CardBody>
                <Tile>RC</Tile>
                <CardText variant="subtitle">Rosewod Commons</CardText>
                <CardText variant="subtext">Affordable housing</CardText>
              </CardBody>
            </CheckableCard>
            <CheckableCard checked onChange={noop} style={{ maxWidth: 150 }}>
              <CardBody>
                <Tile>RC</Tile>
                <CardText variant="subtitle">Rosewod Commons</CardText>
                <CardText variant="subtext">Affordable housing</CardText>
              </CardBody>
            </CheckableCard>
          </Stack>
          <BrandCard
            pillText={<span>IN REVIEW &bull; Aug 7, 2026</span>}
            title={<span>We&rsquo;re verifying your details</span>}
            text="Our staff is verifying your details with Roseway Commons.
            We will message you when we’ve confirmed."
            helpText={
              <span>Call or text (555) 123-1234 &bull; 9am - 5pm, Monday to Friday</span>
            }
          >
            <Button className="mt-4">Contact Support</Button>
          </BrandCard>
          <BrandCard text="Are you ready to claim your order at Local Farmers Market?">
            <Button className="mt-4 w-100">Yes</Button>
            <Button variant="outline" className="mt-2 w-100">
              Back
            </Button>
          </BrandCard>
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
      <Section eventKey="inputs" activeKey={activeKey}>
        <h2>Inputs</h2>
        <Stack gap={2} wrap>
          <TextInput
            label="Zip"
            value=""
            helpText="Five digits."
            placeholder="12345 (placeholder)"
            onChange={noop}
          />
          <TextInput
            label="Zip"
            value="97211"
            helpText="Five digits."
            className="is-focus-visible"
            onChange={noop}
          />
          <TextInput
            label="Zip"
            value="9721"
            helpText="Five digits."
            disabled
            onChange={noop}
          />
          <TextInput
            label="Zip"
            value="9721"
            helpText="Five digits."
            error="Zip code is 5 digits."
            onChange={noop}
          />
        </Stack>
        <h2>Checkboxes</h2>
        <Stack direction="vertical" gap={2}>
          <Stack gap={2}>
            <Checkbox label="Checkbox 1" checked={false} onChange={noop} />
            <Checkbox label="Checkbox 2" checked onChange={noop} />
            <Checkbox checked={false} onChange={noop} />
          </Stack>
          <Stack gap={2}>
            <Switch label="Switch 1" checked={false} onChange={noop} />
            <Switch label="Switch 2" checked onChange={noop} />
            <Switch checked={false} onChange={noop} />
          </Stack>
          <CheckboxCard
            title="When an order is ready"
            text="A text the morning it lands"
            checked={false}
            onChange={noop}
          />
          <CheckboxCard
            title="When an order is ready"
            text="A text the morning it lands"
            checked
            onChange={noop}
          />
          <SwitchRow
            title="Text me about my orders"
            text="Standard message rates apply"
            checked={false}
          />
          <SwitchRow
            title="Text me about my orders"
            text="Standard message rates apply"
            checked
          />
        </Stack>
        <h2>Select</h2>
        <Stack direction="vertical" gap={2}>
          <Select
            label="Select"
            value="optb"
            options={[
              { label: "Option A", value: "opta" },
              { label: "Option B", value: "optb" },
              { label: "Option C", value: "optc" },
              { label: "Option D", value: "optd" },
            ]}
            onChange={noop}
          />
        </Stack>
      </Section>
      <Section eventKey="progress" activeKey={activeKey}>
        <h2>Progress</h2>
        <Stack direction="vertical" gap={1}>
          <Progress value={0} />
          <Progress value={37} />
          <Progress value={50} />
          <Progress value={96} />
          <Progress value={100} />
          <Stack gap={2}>
            <Progress variant="circle" value={0} />
            <Progress variant="circle" value={37} />
            <Progress variant="circle" value={50} />
            <Progress variant="circle" value={96} />
            <Progress variant="circle" value={100} />
          </Stack>
        </Stack>
      </Section>
      <Section eventKey="checklist" activeKey={activeKey}>
        <h2>Checklist</h2>
        <Checklist>
          <ChecklistItem variant="checked">How it works</ChecklistItem>
          <ChecklistItem variant="checked">Agree</ChecklistItem>
          <ChecklistItem variant="current" step={3}>
            Get text
          </ChecklistItem>
          <ChecklistItem step={4}>Get link</ChecklistItem>
          <ChecklistItem step={5}>Finish linking</ChecklistItem>
        </Checklist>
      </Section>
      <Section eventKey="nav" activeKey={activeKey}>
        <Nav>
          <NavOption label="Home" Icon={HomeIcon} />
          <NavOption label="Offers" Icon={BuildingStorefrontIcon} active />
          <NavOption label="Map" Icon={ShoppingCartIcon} />
          <NavOption label="More" Icon={SquaresPlusIcon} />
        </Nav>
      </Section>
      <Section eventKey="dialogs" activeKey={activeKey}>
        <Dialog
          open={dialogToggle.isOn}
          onClose={dialogToggle.turnOff}
          labelledBy="delete-confirm"
          initialFocusRef={dialogFocusRef}
        >
          <Card>
            <CardBody>
              <Stack direction="vertical" gap={3}>
                <DialogHeader id="delete-confirm">
                  Are you sure you want to delete this item?
                </DialogHeader>
                <p>This cannot be undone.</p>
                <ButtonGroup>
                  <Button
                    variant="text"
                    ref={dialogFocusRef}
                    className="btn btn-secondary"
                    onClick={dialogToggle.turnOff}
                  >
                    Cancel
                  </Button>
                  <Button variant="primary" onClick={dialogToggle.turnOff}>
                    Delete
                  </Button>
                </ButtonGroup>
              </Stack>
            </CardBody>
          </Card>
        </Dialog>
        <Button onClick={dialogToggle.turnOn}>Open Dialog</Button>
      </Section>
      <Section eventKey="loaders" activeKey={activeKey}>
        <Stack gap={3}>
          <IndeterminateLoader variant="plain" size={20} />
          <IndeterminateLoader variant="plain" size={40} />
          <IndeterminateLoader variant="plain" />
        </Stack>
        <div className="position-relative">
          <p>{LOREM_IPSUM}</p>
          <IndeterminateLoader variant="content" />
        </div>
        <IndeterminateLoader variant="screen" style={{ marginTop: 80 }} />
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
] as const;

const BUTTON_STATES = ["", "is-hover", "is-focus-visible", "is-disabled"];

function Section({ eventKey, activeKey, children }) {
  if (eventKey !== activeKey) {
    return null;
  }
  return <div className="mt-2 mx-2">{children}</div>;
}

const LOREM_IPSUM = (
  <span>
    Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras sed ligula blandit,
    dictum massa quis, lobortis metus. Nunc ac justo nec ante tincidunt euismod ut vel
    libero. <a href="#">Sed gravida porta malesuada.</a> Sed iaculis pretium urna vel
    elementum. Sed vel egestas nisi, eget molestie diam. Vivamus urna elit, elementum ut
    justo et, cursus interdum tortor. Proin suscipit ac neque sit amet iaculis. In ut erat
    in mauris feugiat ornare. Sed condimentum non enim ut lacinia. Fusce ac libero cursus
    magna vulputate rutrum. Nullam dapibus enim eu facilisis cursus. Mauris vel est a
    lacus venenatis sollicitudin et eget turpis. Lorem ipsum dolor sit amet, consectetur
    adipiscing elit. Nunc at viverra tellus. Nunc vitae nulla nisl.
  </span>
);
