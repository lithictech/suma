import TODO from "../components/TODO.tsx";
import externalLinks from "../modules/externalLinks.ts";
import signOut from "../modules/signOut.ts";
import ExternalLink from "../routing/ExternalLink.tsx";
import { externalUrl, RoutePath, RoutePathOrUrl } from "../routing/RoutePath.ts";
import { TintColor } from "../types/theme";
import Button from "../ui/Button.tsx";
import Card from "../ui/Card.tsx";
import CardBody from "../ui/CardBody.tsx";
import CardText from "../ui/CardText.tsx";
import DivLink from "../ui/DivLink.tsx";
import Icon, { IconPropsIcon } from "../ui/Icon.tsx";
import IconChip from "../ui/IconChip.tsx";
import Page from "../ui/Page.tsx";
import PageHeader from "../ui/PageHeader.tsx";
import Stack from "../ui/Stack";
import {
  BanknotesIcon,
  EyeIcon,
  LifebuoyIcon,
  QuestionMarkCircleIcon,
  ShieldCheckIcon,
  ShoppingBagIcon,
  TruckIcon,
  UserCircleIcon,
} from "@heroicons/react/24/outline";
import LanguageIcon from "@heroicons/react/24/outline/LanguageIcon";

export default function MenuPage() {
  return (
    <Page appNav>
      <PageHeader title="Menu" subtitle="Account details, purchase history, and more." />
      <Card>
        <NavArea
          to="/preferences"
          color="primary"
          icon={UserCircleIcon}
          title="Account"
          text="Your profile and contact details"
        />
        <hr />
        <NavArea
          to="/funding"
          color="danger"
          icon={BanknotesIcon}
          title="Payment methods"
          text="Manage your saved payment methods."
        />
        <hr />
        <NavArea
          to="/private-accounts"
          color="danger"
          icon={ShieldCheckIcon}
          title="Private Accounts"
          text="Manage your private accounts in other services."
        />
        <hr />
        <NavArea
          to="/order-history"
          icon={ShoppingBagIcon}
          color="secondary"
          title="Order History"
          text="Everything you have picked up"
        />
        <hr />
        <NavArea
          to="/trips"
          icon={TruckIcon}
          color="success"
          title="Trip History"
          text="Trips you have taken"
        />
        <hr />
        <NavArea
          to="/ledgers"
          icon={BanknotesIcon}
          color="danger"
          title="Transactions"
          text="Payments, credits, and balances"
        />
      </Card>
      <Card>
        <SimpleNavAreaLink to="/preferences" icon={LanguageIcon} title="Language" />
        <hr />
        <SimpleNavAreaLink to="/theme" icon={EyeIcon} title="Theme" />
        <hr />
      </Card>
      <Card>
        <SimpleNavAreaLink
          to={externalUrl(externalLinks.supportMailto)}
          icon={LifebuoyIcon}
          title="Support"
        />
        <hr />
        <SimpleNavAreaLink to="/sitemap" icon={QuestionMarkCircleIcon} title="Sitemap" />
        <hr />
        <SimpleNavAreaLink
          to="/privacy-policy"
          icon={QuestionMarkCircleIcon}
          title="Privacy Policy"
        />
        <hr />
        <SimpleNavAreaLink
          to="/terms-of-use"
          icon={QuestionMarkCircleIcon}
          title="Terms of Use"
        />
        <hr />
        <Stack row className="justify-content-evenly py-3">
          <ExternalLink href="https://www.instagram.com/mysuma/" aria-label="Instagram">
            <Icon icon={QuestionMarkCircleIcon} />
          </ExternalLink>
          <ExternalLink
            href="https://www.linkedin.com/company/mysuma/"
            aria-label="LinkedIn"
          >
            <Icon icon={QuestionMarkCircleIcon} />
          </ExternalLink>
        </Stack>
      </Card>
      <Card className="d-flex">
        <Button variant="text" inline style={{ flex: 1 }} onClick={signOut}>
          <SimpleNavArea title="Sign Out" icon={QuestionMarkCircleIcon} />
        </Button>
      </Card>
    </Page>
  );
}

function NavArea({
  to,
  icon,
  color,
  title,
  text,
}: {
  to: RoutePath;
  icon: IconPropsIcon;
  color: TintColor;
  title: string;
  text: string;
}) {
  return (
    <DivLink to={to}>
      <CardBody>
        <Stack row gap={2} className="justify-content-between" center>
          <Stack row gap={4} center>
            <IconChip size={48} icon={icon} color={color} />
            <Stack col>
              <CardText variant="title">{title}</CardText>
              <CardText variant="subtext">{text}</CardText>
            </Stack>
          </Stack>
          <Icon icon="right" />
        </Stack>
      </CardBody>
    </DivLink>
  );
}

interface SimpleNavAreaProps {
  icon: IconPropsIcon;
  title: string;
}

function SimpleNavArea({ icon, title }: SimpleNavAreaProps) {
  return (
    <CardBody>
      <Stack row gap={2} className="justify-content-between" center>
        <Stack row gap={3} center>
          <Icon icon={icon} className="color-primary" />
          <CardText variant="subtitle">{title}</CardText>
        </Stack>
        <Icon icon="right" />
      </Stack>
    </CardBody>
  );
}

interface SimpleNavAreaLinkProps extends SimpleNavAreaProps {
  to: RoutePathOrUrl;
}

function SimpleNavAreaLink({ to, ...rest }: SimpleNavAreaLinkProps) {
  return (
    <DivLink to={to}>
      <SimpleNavArea {...rest} />
    </DivLink>
  );
}
