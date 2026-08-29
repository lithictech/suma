import ErrorPage from "../components/ErrorPage.tsx";
import TripDetail from "../components/TripDetail.tsx";
import useUrlMarshal from "../state/useUrlMarshal";
import Page from "../ui/Page.tsx";
import PageHeader from "../ui/PageHeader.tsx";
import dayjs from "dayjs";

export default function TripDetailPage() {
  const { unmarshalFromUrl } = useUrlMarshal();
  let trip: MobilityTrip;
  try {
    trip = unmarshalFromUrl(
      new URLSearchParams(window.location.search).get("trip")
    ) as MobilityTrip;
  } catch {
    return <ErrorPage variant="back" page />;
  }
  return (
    <Page>
      <PageHeader title={dayjs(trip.beganAt).format("ll")} back="/trips" />
      <TripDetail trip={trip} />
    </Page>
  );
}
