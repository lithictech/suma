import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import LayoutContainer from "../components/LayoutContainer";
import PageLoader from "../components/PageLoader";
import TripList from "../components/TripList.tsx";
import { t } from "../localization";
import useAsyncFetch from "../state/useAsyncFetch";
import Page from "../ui/Page.tsx";
import isEmpty from "lodash/isEmpty";

export default function Trips() {
  const {
    state: trips,
    loading: tripsLoading,
    error: tripsError,
  } = useAsyncFetch<MobilityTripCollection>(api.getMobilityTrips, {
    default: {} as MobilityTripCollection,
    pickData: true,
  });

  if (tripsError) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }

  return (
    <Page appNav>
      <LayoutContainer gutters>
        <h2>{t("titles.trips")}</h2>
        <p className="text-secondary">{t("trips.intro")}</p>
      </LayoutContainer>
      {tripsLoading ? (
        <PageLoader />
      ) : isEmpty(trips.items) ? (
        <LayoutContainer>{t("trips.empty")}</LayoutContainer>
      ) : (
        <TripList tripCollection={trips} />
      )}
    </Page>
  );
}
