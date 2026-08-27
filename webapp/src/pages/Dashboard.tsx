import api from "../api";
import AddToHomescreen from "../components/AddToHomescreen";
import AppNav from "../components/AppNav.tsx";
import LayoutContainer from "../components/LayoutContainer";
import PageLoader from "../components/PageLoader";
import ProgramCard from "../components/ProgramCard.tsx";
import SeeAlsoAlert from "../components/SeeAlsoAlert";
import { t } from "../localization";
import readOnlyReason from "../modules/readOnlyReason";
import useAsyncFetch from "../state/useAsyncFetch";
import useUser from "../state/useUser";
import Alert from "../ui/Alert";
import Page from "../ui/Page.tsx";
import Stack from "../ui/Stack";
import { Link } from "react-router-dom";

export default function Dashboard() {
  const {
    state: dashboard,
    loading: dashboardLoading,
    error: dashboardError,
  } = useAsyncFetch<Dashboard>(api.dashboard, {
    default: {} as Dashboard,
    pickData: true,
  });
  if (dashboardError) {
    return (
      <LayoutContainer top>
        <h2>{t("errors.something_went_wrong_title")}</h2>
        <p>{t("errors.unhandled_error")}</p>
      </LayoutContainer>
    );
  }
  return (
    <Page>
      <Page buffer>
        <TopAlerts dashboard={dashboard} />
        <AddToHomescreen />
        {dashboardLoading ? (
          <PageLoader buffered />
        ) : (
          <Stack col gap={3}>
            {dashboard.programs.map((program) => (
              <ProgramCard key={program.name} {...program} />
            ))}
          </Stack>
        )}
      </Page>
      <AppNav />
    </Page>
  );
}

function TopAlerts({ dashboard }: { dashboard: Dashboard }) {
  const { user, registrationSession } = useUser();
  return (
    <>
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
    </>
  );
}
