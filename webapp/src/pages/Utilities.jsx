import utilitiesHeaderImage from "../assets/images/onboarding-utilities.jpg";
import WaitingListPage from "../components/WaitingListPage";
import { mdp, t } from "../localization";
import React from "react";

export default function Utilities() {
  return (
    <WaitingListPage
      feature="utilities"
      imgSrc={utilitiesHeaderImage}
      imgAlt="Solar Panels"
      title={t("utilities:page_title")}
      text={mdp("utilities:intro")}
    />
  );
}
