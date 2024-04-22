import mobilityHeaderImage from "../assets/images/onboarding-mobility.jpg";
import LayoutContainer from "../components/LayoutContainer";
import { MdLink } from "../components/SumaMarkdown";
import WaitingListPage from "../components/WaitingListPage";
import Map from "../components/mobilitymap/Map";
import config from "../config";
import { mdx, t } from "../localization";
import React from "react";

export default function Mobility() {
  return config.featureMobility ? (
    <>
      <LayoutContainer top gutters>
        <h5>{t("mobility:title")}</h5>
        {mdx("mobility:intro", {
          overrides: {
            a: { component: MdLink },
            p: {
              props: {
                className: "text-secondary",
              },
            },
          },
        })}
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
