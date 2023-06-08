import scooterIcon from "../assets/images/kick-scooter.png";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import { t } from "../localization";
import { dayjs } from "../modules/dayConfig";
import Money from "../shared/react/Money";
import { LayoutContainer } from "../state/withLayout";
import React from "react";
import Badge from "react-bootstrap/Badge";
import ListGroup from "react-bootstrap/ListGroup";
import Stack from "react-bootstrap/Stack";

export default function MobilityTripDetail() {
  // const { id } = useParams();
  // const location = useLocation();
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
  return (
    <LayoutContainer top gutters>
      <LinearBreadcrumbs back="/mobility-trips" />
      <Stack gap={3}>
        <div className="mb-0">
          <h5>
            {dayjs(state.beganAt).format("ll")} &middot; from{" "}
            {dayjs(state.beganAt).format("LT")} to {dayjs(state.endedAt).format("LT")}
          </h5>
          <img
            src={scooterIcon}
            style={{ width: "80px", verticalAlign: "bottom" }}
            alt="scooter icon"
          />
          <ListGroup>
            <ListGroupInfoItem label="Provider" value={state.vendorService.name} />
            <ListGroupInfoItem
              label="Vehicle ID"
              value={<Badge>{state.vehicleId}</Badge>}
            />
            <ListGroupInfoItem label="Trip ID" value={state.tripId} />
            <ListGroupInfoItem label="Total" value={<Money>{state.total}</Money>} />
            <ListGroupInfoItem
              label="Rate"
              value={t("mobility:" + state.rate.localizationKey, {
                surchargeCents: {
                  cents: state.rate.locVars.surchargeCents,
                  currency: state.rate.locVars.surchargeCurrency,
                },
                unitCents: {
                  cents: state.rate.locVars.unitCents,
                  currency: state.rate.locVars.unitCurrency,
                },
              })}
            />
            <ListGroupInfoItem label="Pickup location" value={state.location} />
          </ListGroup>
        </div>
      </Stack>
    </LayoutContainer>
  );
}

function ListGroupInfoItem({ label, value }) {
  return (
    <ListGroup.Item>
      <span className="text-secondary">{label}:</span> {value}
    </ListGroup.Item>
  );
}

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
