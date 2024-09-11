import utilitiesHeaderImage from "../assets/images/onboarding-utilities.jpg";
import WaitingListPage from "../components/WaitingListPage";
import { t } from "../localization";
import React from "react";

export default function Utilities() {
  return (
    <WaitingListPage
      feature="utilities"
      imgSrc={utilitiesHeaderImage}
      imgAlt="Solar Panels"
      title={t("utilities:page_title")}
      text={t("utilities:intro")}
    />
  );
}
