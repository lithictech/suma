import mobilityHeaderImage from "../assets/images/onboarding-mobility.jpg";
import ExternalLink from "../components/ExternalLink";
import WaitingListPage from "../components/WaitingListPage";
import Map from "../components/mobilitymap/Map";
import config from "../config";
import { t } from "../localization";
import externalLinks from "../modules/externalLinks";
import { LayoutContainer } from "../state/withLayout";
import React from "react";

export default function Mobility() {
  return config.featureMobility ? (
    <>
      <LayoutContainer top gutters>
        <h5>{t("mobility:title")}</h5>
        <p className="text-secondary">
          {t("mobility:intro")}
          <br />
          <ExternalLink href={externalLinks.mobilityInfoLink}>
            {t("common:learn_more")}
          </ExternalLink>
        </p>
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
  );
}
