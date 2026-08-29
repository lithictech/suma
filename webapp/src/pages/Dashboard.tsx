import api from "../api";
import AddToHomescreen from "../components/AddToHomescreen";
import AsyncContent from "../components/AsyncContent.tsx";
import ProgramCard from "../components/ProgramCard.tsx";
import TODO from "../components/TODO.tsx";
import useAsyncFetch from "../state/useAsyncFetch";
import useUser from "../state/useUser";
import Page from "../ui/Page.tsx";
import Stack from "../ui/Stack";

export default function Dashboard() {
  const {
    state: dashboard,
    loading: dashboardLoading,
    error: dashboardError,
  } = useAsyncFetch<Dashboard>(api.dashboard, {
    default: {} as Dashboard,
    pickData: true,
  });
  return (
    <Page appNav>
      <TopAlerts dashboard={dashboard} />
      <AddToHomescreen />
      <AsyncContent loading={dashboardLoading} error={dashboardError}>
        <Stack col gap={3}>
          {dashboard.programs.map((program) => (
            <ProgramCard key={program.name} {...program} />
          ))}
        </Stack>
      </AsyncContent>
    </Page>
  );
}

function TopAlerts({ dashboard }: { dashboard: Dashboard }) {
  const { user, registrationSession } = useUser();
  return (
    <TODO>
      {dashboard}
      {user}
      {registrationSession}
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
