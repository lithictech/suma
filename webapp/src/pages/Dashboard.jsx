import api from "../api";
import foodHeaderImage from "../assets/images/onboarding-food.jpg";
import AddToHomescreen from "../components/AddToHomescreen";
import ExternalLink from "../components/ExternalLink";
import LayoutContainer from "../components/LayoutContainer";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink";
import SeeAlsoAlert from "../components/SeeAlsoAlert";
import SumaImage from "../components/SumaImage";
import { imageAltT, t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import externalLinks from "../modules/externalLinks";
import readOnlyReason from "../modules/readOnlyReason";
import { anyMoney } from "../shared/money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useUser from "../state/useUser";
import React from "react";
import Alert from "react-bootstrap/Alert";
import Button from "react-bootstrap/Button";
import Stack from "react-bootstrap/Stack";
import { Link } from "react-router-dom";

export default function Dashboard() {
  const {
    state: dashboard,
    loading: dashboardLoading,
    error: dashboardError,
  } = useAsyncFetch(api.dashboard, {
    default: {},
    pickData: true,
  });
  if (dashboardError) {
    return (
      <LayoutContainer top>
        <h2>{t("errors:something_went_wrong_title")}</h2>
        <p>{t("errors:unhandled_error")}</p>
      </LayoutContainer>
    );
  }
  return (
    <>
      <TopAlerts />
      <img
        src={foodHeaderImage}
        alt={imageAltT("local_food_stand")}
        className="thin-header-image"
      />
      <LayoutContainer gutters top>
        <div className="font-serif lead d-flex flex-column gap-3">
          <p className="mb-0">{t("dashboard:intro")}</p>
          <ExternalLink
            href={externalLinks.sumaIntroLink}
            className="text-dark fw-semibold"
            style={{ alignSelf: "flex-end" }}
          >
            {t("dashboard:about_suma")}
          </ExternalLink>
        </div>
        <AddToHomescreen />
      </LayoutContainer>
      {anyMoney(dashboard.cashBalance) && (
        <Alert className="border-radius-0 my-3" variant="success">
          {t("dashboard:availableCash", { balance: dashboard.cashBalance })}
        </Alert>
      )}
      {dashboardLoading ? (
        <PageLoader buffered />
      ) : (
        <LayoutContainer gutters>
          <Stack gap="3">
            {dashboard.programs.map((program) => (
              <ProgramCard key={program.name} {...program} />
            ))}
          </Stack>
        </LayoutContainer>
      )}
    </>
  );
}

function TopAlerts() {
  const { user } = useUser();
  return (
    <>
      {user.ongoingTrip && (
        <Alert variant="danger" className="border-radius-0">
          <p>{t("dashboard:check_ongoing_trip")}</p>
          <div className="d-flex justify-content-end">
            <Link to="/mobility" className="btn btn-sm btn-danger px-3">
              {t("dashboard:check_ongoing_trip_button")}
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
        <Alert variant="danger" className="border-radius-0">
          {readOnlyReason(user, "read_only_unverified")}
        </Alert>
      )}
      {user.unclaimedOrdersCount > 0 && (
        <SeeAlsoAlert
          alertClass="blinking-alert mb-0"
          variant="success"
          label={t("dashboard:claim_orders")}
          iconClass="bi-bag-check-fill"
          show
          to="/unclaimed-orders"
        />
      )}
    </>
  );
}

function ProgramCard({ name, description, image, periodEnd, appLink, appLinkText }) {
  return (
    <div className="position-relative bg-primary rounded-2 p-3 pt-5 mt-4 w-100">
      <h5 className="border border-2 border-dark rounded-2 bg-white py-2 px-3 position-absolute text-truncate hamburger-header">
        {name}
      </h5>
      <Link to={appLink} className="flex-shrink-0 overflow-hidden position-relative">
        <SumaImage
          image={image}
          w={450}
          h={130}
          style={{ maxWidth: "100%" }}
          params={{ crop: "entropy" }}
        />
      </Link>
      <p className="mt-3">{description}</p>
      <p className="small">
        {t("dashboard:program_ends", { date: dayjs(periodEnd).format("ll") })}
      </p>
      <Button
        as={RLink}
        href={appLink}
        state={{ fromIndex: true }}
        variant="outline-dark"
        className="h6 mb-0"
        size="sm"
      >
        {appLinkText} <i className="bi bi-arrow-right-circle-fill ms-1"></i>
      </Button>
    </div>
  );
}
