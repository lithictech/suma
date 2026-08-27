import mobilityHeaderImage from "../assets/images/onboarding-mobility.jpg";
import AppNav from "../components/AppNav.tsx";
import FeaturePageHeader from "../components/FeaturePageHeader";
import WaitingList from "../components/WaitingList";
import Map from "../components/mobilitymap/Map";
import config from "../config";
import { imageAltT, t } from "../localization";
import Page from "../ui/Page.tsx";
import React from "react";

export default function Mobility() {
  if (!config.featureMobility) {
    return (
      <FeaturePageHeader
        imgSrc={mobilityHeaderImage}
        imgAlt={imageAltT("person_riding_scooter")}
      >
        <WaitingList
          title={t("mobility.title")}
          text={t("mobility.intro")}
          survey={{
            topic: "mobility_waitlist",
            questions: [],
          }}
        />
      </FeaturePageHeader>
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
