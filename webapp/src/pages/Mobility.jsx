import mobilityHeaderImage from "../assets/images/onboarding-mobility.jpg";
import LayoutContainer from "../components/LayoutContainer";
import WaitingListPage from "../components/WaitingListPage";
import Map from "../components/mobilitymap/Map";
import config from "../config";
import { t } from "../localization";
import React from "react";

export default function Mobility() {
  return config.featureMobility ? (
    <>
      <LayoutContainer top gutters>
        <h5>{t("mobility:title")}</h5>
        <p className="text-secondary">{t("mobility:intro")}</p>
      </LayoutContainer>
      <Map />
    </>
  ) : (
    <div className="pb-4">
      <WaitingListPage
        feature="mobility"
        imgSrc={mobilityHeaderImage}
        imgAlt="Scooter Mobility"
        title={t("mobility:title")}
        text={t("mobility:intro")}
      />
    </div>
  );
}
