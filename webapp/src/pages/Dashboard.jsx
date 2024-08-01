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
import first from "lodash/first";
import isEmpty from "lodash/isEmpty";
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
      <TopAlerts
        offerings={dashboard.offerings}
        mobilityVehiclesAvailable={dashboard.mobilityVehiclesAvailable}
      />
      <img src={foodHeaderImage} alt={t("food:title")} className="thin-header-image" />
      <LayoutContainer gutters top>
        <h5 className="lead mb-3">{t("dashboard:intro")}</h5>
        <div className="d-flex justify-content-end">
          <ExternalLink
            href={externalLinks.sumaIntroLink}
            className="btn btn-sm btn-outline-info"
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
          <h4>Current Offerings</h4>
          <Stack gap={3}>
            {dashboard.vendibleGroupings.map(({ name, vendibles }) => (
              <HamburgerSection key={name} name={name}>
                {vendibles.map((v) => (
                  <VendibleCard key={v.name} {...v.vendible} className="border-0" />
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
    <div className="position-relative bg-primary rounded-5 p-3 pt-5 mt-4 w-100">
      <h4 className="border border-2 border-dark rounded-5 bg-white py-2 px-3 position-absolute text-truncate hamburger-header">
        {name}
      </h4>
      <Stack gap={3}>{children}</Stack>
    </div>
  );
}

function TopAlerts({ offerings, mobilityVehiclesAvailable }) {
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
      {user.unclaimedOrdersCount === 0 ? (
        <>
          <SeeAlsoAlert
            variant="info"
            textVariant="muted"
            label={t("dashboard:check_available_food")}
            alertClass={Boolean(mobilityVehiclesAvailable) && "mb-0"}
            iconClass="bi-bag-fill"
            show={!isEmpty(offerings)}
            to={offerings?.length > 1 ? "/food" : `/food/${first(offerings)?.id}`}
          />
          <SeeAlsoAlert
            variant="info"
            textVariant="muted"
            label={t("dashboard:check_available_mobility")}
            iconClass="bi-scooter"
            alertClass="mb-0"
            show={Boolean(mobilityVehiclesAvailable)}
            to="/mobility"
          />
        </>
      ) : (
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
