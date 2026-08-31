import AsyncContent from "../components/AsyncContent.tsx";
import ProgramCard from "../components/ProgramCard.tsx";
import { t } from "../localization";
import { AppError } from "../modules/feedback.ts";
import readOnlyReason from "../modules/readOnlyReason.ts";
import Alert, { AlertVariant } from "../ui/Alert.tsx";
import Stack from "../ui/Stack";
import { HandRaisedIcon, ShoppingBagIcon } from "@heroicons/react/24/outline";

interface DashboardProps {
  user: CurrentMember;
  dashboard: Dashboard;
  loading: boolean;
  error: AppError | null;
}
export default function DashboardC({ user, dashboard, loading, error }: DashboardProps) {
  return (
    <>
      <TopAlerts user={user} dashboard={dashboard} />
      <AsyncContent loading={loading} error={error}>
        {() => (
          <Stack col gap={3}>
            {dashboard.programs.map((program) => (
              <ProgramCard key={program.name} {...program} />
            ))}
          </Stack>
        )}
      </AsyncContent>
    </>
  );
}

function TopAlerts({ user, dashboard }: { user: CurrentMember; dashboard: Dashboard }) {
  return (
    <>
      {user.registrationLink && (
        <Alert
          variant="success"
          text={t("dashboard.partner_signup_available", {
            organization: user.registrationLink.organizationName,
          })}
          icon={HandRaisedIcon}
          to="/partner-signup"
        />
      )}
      {user.ongoingTrip && (
        <Alert variant="danger" text={t("dashboard.check_ongoing_trip")} to="/mobility" />
      )}
      {readOnlyReason(user, "read_only_unverified") && (
        <Alert
          variant="danger"
          text={readOnlyReason(user, "read_only_unverified")!.render()}
        />
      )}
      {user.unclaimedOrdersCount > 0 && (
        <Alert
          variant="success"
          text={t("dashboard.claim_orders")}
          icon={ShoppingBagIcon}
          to="/unclaimed-orders"
        />
      )}
      {dashboard?.alerts?.map(({ localizationKey, localizationParams, variant }) => (
        <Alert
          key={localizationKey}
          variant={variant as AlertVariant}
          text={t(localizationKey, localizationParams)}
        />
      ))}
    </>
  );
}
