import AppNav from "../components/AppNav";
import ExternalLink from "../components/ExternalLink";
import Map from "../components/mobilitymap/Map";
import { t } from "../localization";
import externalLinks from "../modules/externalLinks";
import { LayoutContainer } from "../state/withLayout";
import React from "react";

export default function Mobility() {
  return (
    <>
      <AppNav />
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
  );
}
