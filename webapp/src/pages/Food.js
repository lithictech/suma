import foodImage from "../assets/images/onboarding-food.jpg";
import AppNav from "../components/AppNav";
import { mdp, t } from "../localization";
import { LayoutContainer } from "../state/withLayout";
import React from "react";
import Button from "react-bootstrap/Button";

export default function Food() {
  return (
    <>
      <AppNav />
      <img
        src={foodImage}
        className="thin-header-image"
        alt="Fresh produce in a market"
      />
      <LayoutContainer top gutters>
        <h2>{t("food:page_title")}</h2>
        {mdp("food:intro_md")}
        <div className="button-stack mt-4">
          <Button variant="outline-primary">{t("common:join_waitlist")}</Button>{" "}
        </div>
      </LayoutContainer>
    </>
  );
}
