import api from "../api";
import AsyncContent from "../components/AsyncContent.tsx";
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
  });

  return (
    <Page appNav>
      <PageHeader title={t("titles.trips")} subtitle={t("trips.intro")} />
      <AsyncContent loading={tripsLoading} error={tripsError}>
        <TripList tripCollection={trips} />
      </AsyncContent>
    </Page>
  );
}
