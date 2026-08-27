import AppNav from "../components/AppNav.tsx";
import TODO from "../components/TODO.tsx";
import WaitingList from "../components/WaitingList";
import Map from "../components/mobilitymap/Map";
import config from "../config";
import { t } from "../localization";
import Page from "../ui/Page.tsx";

export default function Mobility() {
  if (!config.featureMobility) {
    return (
      <TODO>
        <WaitingList
          title={t("mobility.title")}
          text={t("mobility.intro")}
          survey={{
            topic: "mobility_waitlist",
            questions: [],
          }}
        />
      </TODO>
    );
  }
  return <MobilityImpl />;
}

function MobilityImpl() {
  return (
    <Page style={{ height: "100vh" }}>
      <div className="h-100">
        <Map />
      </div>
      <AppNav />
    </Page>
  );
}
