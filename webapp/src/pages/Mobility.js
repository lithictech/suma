import mobilityHeaderImage from "../assets/images/onboarding-mobility.jpg";
import ExternalLink from "../components/ExternalLink";
import WaitingListPage from "../components/WaitingListPage";
import Map from "../components/mobilitymap/Map";
import config from "../config";
import { t } from "../localization";
import externalLinks from "../modules/externalLinks";
import { LayoutContainer } from "../state/withLayout";
import React from "react";
import { Link } from "react-router-dom";

export default function Mobility() {
  return config.featureMobility ? (
    <>
      <LayoutContainer top gutters>
        <h2>{t("mobility:title")}</h2>
        <p className="text-secondary">
          {t("mobility:intro")}
          <br />
          <ExternalLink href={externalLinks.mobilityInfoLink}>
            {t("common:learn_more")}
          </ExternalLink>
        </p>
        <h4 className="my-3">
          <Link to="/mobility-trips" className="text-decoration-none">
            <span className="text-dark me-1">Previous trips</span>
            <i className="bi-arrow-right"></i>
          </Link>
        </h4>
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
      <LayoutContainer top gutters>
        <hr />
        <h4 className="my-3">
          <Link to="/mobility-trips" className="text-decoration-none">
            <span className="text-dark me-1">Previous trips</span>
            <i className="bi-arrow-right"></i>
          </Link>
        </h4>
      </LayoutContainer>
    </div>
  );
}
