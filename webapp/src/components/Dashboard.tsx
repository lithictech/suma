import AsyncContent from "../components/AsyncContent.tsx";
import { dt, t } from "../localization";
import { AppError } from "../modules/feedback.ts";
import readOnlyReason from "../modules/readOnlyReason.ts";
import Link from "../routing/Link.tsx";
import { untypedRoutePath } from "../routing/RoutePath.ts";
import { ThemeColor, ThemeColorSpec } from "../types/theme";
import Alert from "../ui/Alert.tsx";
import Button from "../ui/Button.tsx";
import Card from "../ui/Card.tsx";
import CardBody from "../ui/CardBody.tsx";
import Chip from "../ui/Chip.tsx";
import Progress from "../ui/Progress.tsx";
import Stack from "../ui/Stack";
import TextHeader from "../ui/TextHeader.tsx";
import Money from "../uir/Money.tsx";
import SumaImage from "./SumaImage.tsx";
import { HandRaisedIcon, ShoppingBagIcon } from "@heroicons/react/24/outline";

interface DashboardProps {
  user: CurrentMember;
  dashboard: Dashboard;
  loading: boolean;
  error: AppError | null;
}
export default function Dashboard({ user, dashboard, loading, error }: DashboardProps) {
  return (
    <AsyncContent loading={loading} error={error}>
      {() => (
        <Stack col gap={6}>
          <TopAlerts user={user} dashboard={dashboard} />
          <Savings dashboard={dashboard} />
          <TextHeader
            variant="section"
            title="Ways to save"
            subtitle="Programs pay part of the price for you. Pick one to see what&rsquo;s in it."
          />
          <ProgramsStack dashboard={dashboard} />
        </Stack>
      )}
    </AsyncContent>
  );
}

function TopAlerts({ user, dashboard }: { user: CurrentMember; dashboard: Dashboard }) {
  const alerts = [
    user.registrationLink && (
      <Alert
        color="success"
        text={t("dashboard.partner_signup_available", {
          organization: user.registrationLink.organizationName,
        })}
        icon={HandRaisedIcon}
        to="/partner-signup"
      />
    ),
    user.ongoingTrip && (
      <Alert color="danger" text={t("dashboard.check_ongoing_trip")} to="/mobility" />
    ),
    readOnlyReason(user, "read_only_unverified") && (
      <Alert
        color="danger"
        text={readOnlyReason(user, "read_only_unverified")!.render()}
      />
    ),
    user.unclaimedOrdersCount > 0 && (
      <Alert
        color="success"
        text={t("dashboard.claim_orders")}
        icon={ShoppingBagIcon}
        to="/unclaimed-orders"
      />
    ),
    ...(dashboard?.alerts || []).map(
      ({ localizationKey, localizationParams, variant }) => (
        <Alert
          key={localizationKey}
          color={variant as ThemeColor}
          text={t(localizationKey, localizationParams)}
        />
      )
    ),
  ].filter(Boolean);
  if (alerts.length === 0) {
    return null;
  }
  return (
    <Card>
      <CardBody>
        <Stack col gap={3}>
          {alerts}
        </Stack>
      </CardBody>
    </Card>
  );
}

function Savings({ dashboard }: { dashboard: Dashboard }) {
  if (dashboard.lifetimeSavings.cents <= 0) {
    return (
      <Card>
        <CardBody>
          <h1 className="text-center">Your savings start here</h1>
          <p className="font-size-body-sm color-text-muted text-center">
            Join a program to unlock offers on everyday essentials.
          </p>
        </CardBody>
      </Card>
    );
  }
  return (
    <Card>
      <CardBody className="d-flex flex-column align-items-center gap-4">
        <h5 className="color-text-muted">You&rsquo;ve saved</h5>
        <Money as="h1" className="color-success">
          {dashboard.lifetimeSavings}
        </Money>
        <p className="font-size-body-sm color-text-muted text-center">
          Money you didn&rsquo;t have to pay, compared with regular prices.
        </p>
        <div className="w-100">
          <Progress
            variant="bar"
            value={dashboard.lifetimeSavingsRatio}
            completeColor={new ThemeColorSpec("success", "strong")}
            incompleteColor={new ThemeColorSpec("primary", "strong")}
            stroke={12}
          />
        </div>
        <Stack row className="font-size-body-sm" gap={5}>
          <Stack col center>
            <div className="color-text-muted">
              <Chip variant="success" bullet /> Saved
            </div>
            <Money className="font-weight-medium">{dashboard.lifetimeSavings}</Money>
          </Stack>
          <Stack col center>
            <div className="color-text-muted">
              <Chip variant="primary" bullet /> You paid
            </div>
            <Money className="font-weight-medium">{dashboard.lifetimeSavings}</Money>
          </Stack>
        </Stack>
      </CardBody>
    </Card>
  );
}

function ProgramsStack({ dashboard }: { dashboard: Dashboard }) {
  if (!dashboard.programs.length) {
    return <h3 className="text-center">No programs available yet!</h3>;
  }
  return (
    <Stack col gap={3}>
      {dashboard.programs.map((program) => (
        <ProgramCard key={program.name} {...program} />
      ))}
    </Stack>
  );
}

function ProgramCard({ name, description, image, appLink, appLinkText }: Program) {
  const ImageComp = appLink ? Link : "div";
  return (
    <Card>
      <CardBody>
        <Stack row gap={5}>
          <ImageComp to={untypedRoutePath(appLink)}>
            <SumaImage
              image={image || undefined}
              w={72}
              height={72}
              params={{ crop: "entropy", resize: "fill" }}
              style={{ maxWidth: "100%", objectFit: "cover" }}
              className="border-radius"
            />
          </ImageComp>
          <Stack col align="start" gap={3}>
            <h5>{name}</h5>
            <div className="color-text-muted font-size-body-sm">{dt(description)}</div>
            {appLink && (
              <Button
                to={untypedRoutePath(appLink)}
                variant="secondary"
                color="secondary"
                size="sm"
                className="mt-2 program-card-goto"
              >
                {appLinkText}
              </Button>
            )}
          </Stack>
        </Stack>
      </CardBody>
    </Card>
  );
}
