import api from "../api";
import foodHeaderImage from "../assets/images/onboarding-food.jpg";
import AddToHomescreen from "../components/AddToHomescreen";
import ExternalLink from "../components/ExternalLink";
import LayoutContainer from "../components/LayoutContainer";
import PageLoader from "../components/PageLoader";
import SeeAlsoAlert from "../components/SeeAlsoAlert";
import VendibleCard from "../components/VendibleCard";
import { t } from "../localization";
import externalLinks from "../modules/externalLinks";
import readOnlyReason from "../modules/readOnlyReason";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useUser from "../state/useUser";
import React from "react";
import Alert from "react-bootstrap/Alert";
import Stack from "react-bootstrap/Stack";
import { Link } from "react-router-dom";

export default function Dashboard() {
  const { state: dashboard, loading: dashboardLoading } = useAsyncFetch(api.dashboard, {
    default: {},
    pickData: true,
  });
  return (
    <>
      <TopAlerts />
      <img src={foodHeaderImage} alt={t("food:title")} className="thin-header-image" />
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
      {dashboardLoading ? (
        <PageLoader buffered />
      ) : (
        <LayoutContainer top gutters>
          <Stack gap={3}>
            {dashboard.vendibleGroupings.map(({ name, vendibles }) => (
              <HamburgerSection key={name} name={name}>
                {vendibles.map((v) => (
                  <VendibleCard key={v.name} {...v} className="border-0" />
                ))}
              </HamburgerSection>
            ))}
          </Stack>
        </LayoutContainer>
      )}
    </>
  );
}

function HamburgerSection({ name, children }) {
  if (!children) {
    return null;
  }
  return (
    <div className="position-relative bg-primary rounded-2 p-3 pt-5 mt-4 w-100">
      <h5 className="border border-2 border-dark rounded-2 bg-white py-2 px-3 position-absolute text-truncate hamburger-header">
        {name}
      </h5>
      <Stack gap={3}>{children}</Stack>
    </div>
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
