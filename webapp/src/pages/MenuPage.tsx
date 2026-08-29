import externalLinks from "../modules/externalLinks.ts";
import { externalUrl, RoutePath, RoutePathOrUrl } from "../routing/RoutePath.ts";
import { TintColor } from "../types/theme";
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
import MapIcon from "@heroicons/react/24/outline/MapIcon";

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
        <SimpleNavArea
          to={externalUrl(externalLinks.supportMailto)}
          icon={LifebuoyIcon}
          title="Support"
        />
        <hr />
        <SimpleNavArea to="/sitemap" icon={QuestionMarkCircleIcon} title="Sitemap" />
        <hr />
        <SimpleNavArea to="/preferences" icon={LanguageIcon} title="Language" />
        <hr />
        <SimpleNavArea to="/theme" icon={EyeIcon} title="Theme" />
      </Card>
      {/*const iconStyle = { fontSize: "140%" };*/}

      {/*<ExternalLink href="https://www.instagram.com/mysuma/" aria-label="Instagram">*/}
      {/*  <i className="bi bi-instagram me-3" style={iconStyle}></i>*/}
      {/*</ExternalLink>*/}
      {/*<ExternalLink*/}
      {/*  href="https://www.linkedin.com/company/mysuma/"*/}
      {/*  aria-label="LinkedIn"*/}
      {/*>*/}
      {/*  <i className="bi bi-linkedin" style={iconStyle}></i>*/}
      {/*</ExternalLink>*/}
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

function SimpleNavArea({
  to,
  icon,
  title,
}: {
  to: RoutePathOrUrl;
  icon: IconPropsIcon;
  title: string;
}) {
  return (
    <DivLink to={to}>
      <CardBody>
        <Stack row gap={2} className="justify-content-between" center>
          <Stack row gap={3} center>
            <Icon icon={icon} className="color-primary" />
            <CardText variant="subtitle">{title}</CardText>
          </Stack>
          <Icon icon="right" />
        </Stack>
      </CardBody>
    </DivLink>
  );
}
