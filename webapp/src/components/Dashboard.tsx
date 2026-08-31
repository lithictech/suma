import AsyncContent from "../components/AsyncContent.tsx";
import ProgramCard from "../components/ProgramCard.tsx";
import TODO from "../components/TODO.tsx";
import { AppError } from "../modules/feedback.ts";
import Stack from "../ui/Stack";

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
    <TODO>
      {dashboard}
      {user}
      {`
      {registrationSession && (
        <SeeAlsoAlert
          alertClass="blinking-alert mb-0"
          variant="success"
          label={t("dashboard.partner_signup_available", {
            organization: registrationSession.organizationName,
          })}
          iconClass="bi-person-raised-hand"
          show
          to="/partner-signup"
        />
      )}
      {user.ongoingTrip && (
        <Alert variant="danger" className="border-radius-0">
          <p>{t("dashboard.check_ongoing_trip")}</p>
          <div className="d-flex justify-content-end">
            <Link to="/mobility" className="btn btn-sm btn-danger px-3">
              {t("dashboard.check_ongoing_trip_button")}
              <i
                className="bi bi-box-arrow-in-right mx-1"
                role="img"
                aria-label="Map Icon"
              ></i>
            </Link>
          </div>
        </Alert>
      )}
      {readOnlyReason(user, "read_only_unverified") && (
        <Alert variant="danger" className="border-radius-0 mb-0">
          {readOnlyReason(user, "read_only_unverified")}
        </Alert>
      )}
      {user.unclaimedOrdersCount > 0 && (
        <SeeAlsoAlert
          alertClass="blinking-alert mb-0"
          variant="success"
          label={t("dashboard.claim_orders")}
          iconClass="bi-bag-check-fill"
          show
          to="/unclaimed-orders"
        />
      )}
      {dashboard?.alerts?.map(({ localizationKey, localizationParams, variant }) => (
        <Alert
          key={localizationKey}
          variant={variant}
          className="blinking-alert mb-0 border-radius-0"
        >
          {t(localizationKey, localizationParams)}
        </Alert>
      ))}
    `}
    </TODO>
  );
}
