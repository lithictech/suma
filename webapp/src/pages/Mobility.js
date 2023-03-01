import mobilityHeaderImage from "../assets/images/onboarding-mobility.jpg";
import ExternalLink from "../components/ExternalLink";
import WaitingListPage from "../components/WaitingListPage";
import Map from "../components/mobilitymap/Map";
import { t } from "../localization";
import externalLinks from "../modules/externalLinks";
import React from "react";

export default function Mobility() {
  return (
    <>
      <div className="pb-4">
        <WaitingListPage
          feature="mobility"
          imgSrc={mobilityHeaderImage}
          imgAlt="Scooter Mobility"
          title={t("mobility:title")}
          text={
            <>
              <span className="pe-2">{t("mobility:intro")}</span>
              <ExternalLink href={externalLinks.mobilityInfoLink}>
                {t("common:learn_more")}
              </ExternalLink>
            </>
          }
        />
      </div>
      <Map />
    </>
  );
}
