import foodImage from "../assets/images/onboarding-food.jpg";
import WaitingListPage from "../components/WaitingListPage";
import { mdp, t } from "../localization";
import React from "react";

export default function Food() {
  return (
    <WaitingListPage
      feature="food"
      imgSrc={foodImage}
      imgAlt="Fresh produce in a market"
      title={t("food:page_title")}
      text={mdp("food:intro_md")}
    />
  );
}
