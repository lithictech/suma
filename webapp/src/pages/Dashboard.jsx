import api from "../api";
import AddToHomescreen from "../components/AddToHomescreen";
import LayoutContainer from "../components/LayoutContainer";
import OfferingCard from "../components/OfferingCard";
import PageLoader from "../components/PageLoader";
import SeeAlsoAlert from "../components/SeeAlsoAlert";
import { t } from "../localization";
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
  const data = {
    items: [
      {
        title: "Farmers Market",
        items: [
          {
            id: 1,
            description: "Holiday Demo",
            closesAt: Date.now(),
            image: first(dashboard.offerings)?.image,
          },
          {
            id: 2,
            description: "SJFM",
            closesAt: Date.now(),
            image: first(dashboard.offerings)?.image,
          },
        ],
      },
      {
        title: "Lime Scooter Rides",
        items: [
          {
            id: 1,
            description: "Free Lime Scooter Rides",
            closesAt: Date.now(),
            image: first(dashboard.offerings)?.image,
          },
        ],
      },
      {
        title: "Transportation",
        items: [
          {
            id: 1,
            description: "Ride Connection Partnership",
            closesAt: Date.now(),
            image: first(dashboard.offerings)?.image,
          },
        ],
      },
    ],
  };
  return (
    <>
      <TopAlerts
        offerings={dashboard.offerings}
        mobilityVehiclesAvailable={dashboard.mobilityVehiclesAvailable}
      />
      <LayoutContainer gutters>
        <AddToHomescreen />
      </LayoutContainer>
      {dashboardLoading ? (
        <PageLoader buffered />
      ) : (
        <LayoutContainer top gutters>
          <h4>Current Offerings:</h4>
          <Stack gap={3}>
            {data.items.map(({ title, items }) => (
              <HamburgerSection key={title} title={title}>
                {items.map((item) => (
                  <OfferingCard key={item.id} {...item} />
                ))}
              </HamburgerSection>
            ))}
          </Stack>
        </LayoutContainer>
      )}
    </>
  );
}

function HamburgerSection({ title, children }) {
  if (!children) {
    return null;
  }
  return (
    <div className="position-relative bg-primary rounded-5 p-3 pt-5 mt-4">
      <h3 className="border border-2 border-dark rounded-5 bg-white py-2 px-3 position-absolute hamburger-title">
        {title}
      </h3>
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
            show={Boolean(mobilityVehiclesAvailable)}
            to="/mobility"
          />
        </>
      ) : (
        <SeeAlsoAlert
          alertClass="blinking-alert"
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
