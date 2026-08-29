import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import TODO from "../components/TODO.tsx";
import TripList from "../components/TripList.tsx";
import { t } from "../localization";
import useAsyncFetch from "../state/useAsyncFetch";
import Page from "../ui/Page.tsx";
import PageHeader from "../ui/PageHeader.tsx";

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
    return <ErrorScreen />;
  }
  if (tripsLoading) {
    return <TODO />;
  }

  return (
    <Page appNav>
      <PageHeader title={t("titles.trips")} subtitle={t("trips.intro")} />
      <TripList tripCollection={trips} />
    </Page>
  );
}
