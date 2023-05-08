import api from "../api";
import scooterIcon from "../assets/images/kick-scooter.png";
import ErrorScreen from "../components/ErrorScreen";
import FormSaveCancel from "../components/FormSaveCancel";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
import { md, t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useToggle from "../shared/react/useToggle";
import { useErrorToast } from "../state/useErrorToast";
import { useScreenLoader } from "../state/useScreenLoader";
import { LayoutContainer } from "../state/withLayout";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";
import Form from "react-bootstrap/Form";
import ProgressBar from "react-bootstrap/ProgressBar";
import Stack from "react-bootstrap/Stack";
import { useLocation, useParams } from "react-router-dom";

export default function MobilityTripDetail() {
  const { id } = useParams();
  const location = useLocation();
  // const getOrderDetails = React.useCallback(() => api.getOrderDetails({ id }), [id]);
  // const { state, replaceState, loading, error } = useAsyncFetch(getOrderDetails, {
  //   default: {},
  //   pickData: true,
  //   pullFromState: "order",
  //   location,
  // });
  // if (error) {
  //   return (
  //     <LayoutContainer top>
  //       <ErrorScreen />
  //     </LayoutContainer>
  //   );
  // }
  // if (loading) {
  //   return <PageLoader />;
  // }
  const state = {
    id: 1,
    vendorService: {
      name: "Lime",
    },
    vehicleId: "#A1B2C3",
    total: { cents: 0, currency: "US" },
    distanceMiles: 3.44,
    location: "Portland, Oregon 22nd/5th Casavana Street",
    beganAt: new Date("2023-04-01 15:22:00"),
    endedAt: new Date("2023-04-02 15:30:00"),

    tripId: "4599c3de-a923-4466-addb-99aee8c55186",
    undiscountedCost: { cents: 125, currency: "US" },
    // If DB returns a rate, it will be displayed, otherwise we just show the "total" cost
    rate: {
      localizationKey: "mobility_start_and_per_minute",
      locVars: {
        surchargeCents: 125,
        surchargeCurrency: "US",
        unitCents: 25,
        unitCurrency: "US",
      },
    },
  };
  return (
    <>
      <LayoutContainer top gutters>
        <LinearBreadcrumbs back="/mobility-trips" />
      </LayoutContainer>
      <LayoutContainer gutters>
        <Stack gap={3}>
          <div className="mb-0">
            <h5>
              {dayjs(state.beganAt).format("ll")} &middot; from{" "}
              {dayjs(state.beganAt).format("LT")} to {dayjs(state.endedAt).format("LT")}
            </h5>
            <Stack direction="horizontal" className="my-4">
              <img
                src={scooterIcon}
                style={{ width: "40px", verticalAlign: "bottom" }}
                alt="scooter icon"
              />
              <ProgressBar
                className="w-100"
                variant="success"
                now={100}
                label={state.distanceMiles + " miles traveled"}
              />
            </Stack>
            <p className="mb-1">Provider: {state.vendorService.name}</p>
            <p className="mb-1">Vehicle ID: {state.vehicleId}</p>
            <p className="mb-1">Trip ID: {state.tripId}</p>
            <p className="mb-1">{t("food:labels:total", { total: state.total })}</p>
            <p className="mb-1">
              Rate:{" "}
              {t("mobility:" + state.rate.localizationKey, {
                surchargeCents: {
                  cents: state.rate.locVars.surchargeCents,
                  currency: state.rate.locVars.surchargeCurrency,
                },
                unitCents: {
                  cents: state.rate.locVars.unitCents,
                  currency: state.rate.locVars.unitCurrency,
                },
              })}
            </p>
            <p className="mb-1">Location: {state.location}</p>
          </div>
        </Stack>
      </LayoutContainer>
    </>
  );
}
