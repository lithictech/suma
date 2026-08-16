import { useError } from "../state/useError.tsx";
import useScreenLoader from "../state/useScreenLoader.ts";
import useToggle from "../state/useToggle";
import BrandCard from "../ui/BrandCard";
import BreadcrumbBack from "../ui/BreadcrumbBack.tsx";
import Button from "../ui/Button";
import ButtonGroup from "../ui/ButtonGroup";
import Card from "../ui/Card";
import CardBody from "../ui/CardBody";
import CardImage from "../ui/CardImage";
import CardText from "../ui/CardText";
import CheckableCard from "../ui/CheckableCard";
import Checkbox from "../ui/Checkbox";
import CheckboxCard from "../ui/CheckboxCard";
import Checklist from "../ui/Checklist";
import ChecklistItem from "../ui/ChecklistItem";
import Chip from "../ui/Chip";
import Container from "../ui/Container";
import { Dialog } from "../ui/Dialog";
import DialogHeader from "../ui/DialogHeader";
import Form from "../ui/Form.tsx";
import FormError from "../ui/FormError.tsx";
import IndeterminateLoader from "../ui/IndeterminateLoader";
import Nav from "../ui/Nav";
import NavOption from "../ui/NavOption";
import Page from "../ui/Page.tsx";
import PhoneInput from "../ui/PhoneInput.tsx";
import Progress from "../ui/Progress";
import ProgressStepHeader from "../ui/ProgressStepHeader.tsx";
import Select from "../ui/Select";
import Stack from "../ui/Stack";
import Switch from "../ui/Switch";
import SwitchRow from "../ui/SwitchRow";
import TextInput from "../ui/TextInput";
import Tile from "../ui/Tile";
import DefinitionTable from "./DefinitionTable.tsx";
import BuildingStorefrontIcon from "@heroicons/react/24/outline/BuildingStorefrontIcon";
import HomeIcon from "@heroicons/react/24/outline/HomeIcon";
import ShoppingCartIcon from "@heroicons/react/24/outline/ShoppingCartIcon";
import SquaresPlusIcon from "@heroicons/react/24/outline/SquaresPlusIcon";
import React from "react";
import { useController, useForm } from "react-hook-form";

export default function Styleguide() {
  const keys = [
    "typography",
    "buttons",
    "cards",
    "chips",
    "tables",
    "inputs",
    "form",
    "checklist",
    "progress",
    "nav",
    "dialogs",
    "headers",
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
      <Stack direction="horizontal" gap={2} wrap className="px-2">
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
          <h2>Horizontal Group</h2>
          <ButtonGroup>
            <Button>Primary Action</Button>
            <Button variant="secondary">Secondary Action</Button>
          </ButtonGroup>
          <h2>Vertical Group</h2>
          <ButtonGroup vertical>
            <Button>Primary Action</Button>
            <Button variant="secondary">Secondary Action</Button>
          </ButtonGroup>
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
          <CheckableCard checked>
            <CardBody>
              <CardText>This card is checked.</CardText>
            </CardBody>
          </CheckableCard>
          <CheckableCard checked={false}>
            <CardBody>
              <CardText>This card is unchecked.</CardText>
            </CardBody>
          </CheckableCard>
          <CheckableCard checked={false} className="is-focus-visible">
            <CardBody>
              <CardText>This card has focus.</CardText>
            </CardBody>
          </CheckableCard>
          <CheckableCard checked={false} disabled>
            <CardBody>
              <CardText>This card is disabled.</CardText>
            </CardBody>
          </CheckableCard>
          <Stack gap={3}>
            <CheckableCard checked={false} style={{ maxWidth: 150 }}>
              <CardBody>
                <Tile>RC</Tile>
                <CardText variant="subtitle">Rosewod Commons</CardText>
                <CardText variant="subtext">Affordable housing</CardText>
              </CardBody>
            </CheckableCard>
            <CheckableCard checked style={{ maxWidth: 150 }}>
              <CardBody>
                <Tile>RC</Tile>
                <CardText variant="subtitle">Rosewod Commons</CardText>
                <CardText variant="subtext">Affordable housing</CardText>
              </CardBody>
            </CheckableCard>
          </Stack>
          <Stack col>
            <Card>
              <CardBody>
                <Stack col gap={3}>
                  <CardImage>
                    <div style={{ backgroundColor: "var(--tint-success", height: 60 }} />
                  </CardImage>
                  <Chip variant="secondary" className="align-self-start">
                    hello
                  </Chip>
                  <h3>Card with image</h3>
                  <p>Here is detail text.</p>
                </Stack>
              </CardBody>
            </Card>
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
      <Section eventKey="tables" activeKey={activeKey}>
        <Card>
          <CardBody>
            <DefinitionTable
              items={[
                { label: "Much Longer Field Name", value: "Ana Flores" },
                {
                  label: "Eligibility",
                  value: <span>Hacienda CDC &bull; In Review</span>,
                },
                {
                  label: "Address",
                  value:
                    "2001 NE Alberta St, Portland, OR 97211 2001 NE Alberta St, Portland, OR 97211",
                },
              ]}
            />
          </CardBody>
        </Card>
      </Section>
      <Section eventKey="inputs" activeKey={activeKey}>
        <h2>Inputs</h2>
        <Stack gap={2} wrap>
          <TextInput
            label="Zip"
            value=""
            help="Five digits."
            placeholder="12345 (placeholder)"
          />
          <TextInput
            label="Zip"
            value="97211"
            help="Five digits."
            className="is-focus-visible"
          />
          <TextInput label="Zip" value="9721" help="Five digits." disabled />
          <TextInput
            label="Zip"
            value="9721"
            help="Five digits."
            error="Zip code is 5 digits."
          />
        </Stack>
        <h2>Checkboxes</h2>
        <Stack direction="vertical" gap={2}>
          <Stack gap={2}>
            <Checkbox label="Checkbox 1" checked={false} />
            <Checkbox label="Checkbox 2" checked />
            <Checkbox checked={false} />
          </Stack>
          <Checkbox label="Invalid" checked={false} error="Must agree to continue" />
          <Stack gap={2}>
            <Switch label="Switch 1" checked={false} />
            <Switch label="Switch 2" checked />
            <Switch checked={false} />
          </Stack>
          <Switch
            label="Invalid switch"
            checked={false}
            error="Must turn on to continue"
          />
          <CheckboxCard
            title="When an order is ready"
            text="A text the morning it lands"
            checked={false}
          />
          <CheckboxCard
            title="When an order is ready"
            text="A text the morning it lands"
            checked
          />
          <CheckboxCard
            checked={false}
            error="Must check to continue"
            alignCheckbox="start"
          >
            <CardText style={{ maxHeight: 100, overflowY: "scroll" }}>
              {LOREM_IPSUM}
            </CardText>
          </CheckboxCard>
          <CheckboxCard checked={false} alignCheckbox="start">
            <CardText style={{ maxHeight: 100, overflowY: "scroll" }}>
              {LOREM_IPSUM}
            </CardText>
          </CheckboxCard>
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
          />
          <Select
            label="Select"
            value=""
            options={[{ label: "Option A", value: "opta" }]}
            error="Must select an option."
          />
        </Stack>
      </Section>
      <Section eventKey="form" activeKey={activeKey}>
        <FormSection />
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
      <Section eventKey="headers" activeKey={activeKey}>
        <Stack gap={3} vertical>
          <div>
            <BreadcrumbBack back />
          </div>
          <ProgressStepHeader step={1} steps={5} />
          <ProgressStepHeader step={4} steps={5} />
          <ProgressStepHeader step={5} steps={5} />
        </Stack>
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
  return (
    <Stack col gap={3} className="mt-2 mx-2 mb-5">
      {children}
    </Stack>
  );
}

function FormSection() {
  const [error, setError] = useError();
  const screenLoader = useScreenLoader();

  const {
    register,
    handleSubmit,
    clearErrors,
    control,
    formState: { errors },
  } = useForm<{ name: string; phone: string; agree: boolean }>({
    mode: "onBlur",
    reValidateMode: "onBlur",
  });

  const {
    field: { value: agree, onChange: onAgreeChange, ref: agreeRef },
  } = useController({
    name: "agree",
    control,
    rules: { required: "You must agree to continue" },
    defaultValue: false,
  });

  const handleSubmitForm = (data: { name: string; phone: string; agree: boolean }) => {
    screenLoader.turnOn();
    setError();
    console.log(data);
    Promise.delay(300)
      .then(() => {
        if (Math.random() < 0.5) {
          setError(<span>This is a random form error.</span>);
        }
      })
      .finally(screenLoader.turnOff);
  };

  return (
    <Page buffer>
      <Form noValidate onSubmit={handleSubmit(handleSubmitForm)}>
        <Stack col gap={3}>
          <TextInput
            label="Name"
            {...register("name", { required: "Name is required" })}
            error={errors.name?.message}
            autoFocus
            required
          />
          <PhoneInput
            label="Phone number"
            name="phone"
            control={control}
            clearErrors={clearErrors}
            required
          />
          <Checkbox
            ref={agreeRef}
            label="I agree to the terms"
            checked={!!agree}
            onChange={onAgreeChange}
            error={errors.agree?.message}
            required
          />
          <FormError error={error} />
          <ButtonGroup col>
            <Button type="submit">Continue</Button>
            <Button variant="outline">Back</Button>
          </ButtonGroup>
        </Stack>
      </Form>
    </Page>
  );
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
