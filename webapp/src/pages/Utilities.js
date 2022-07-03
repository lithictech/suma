import utilitiesImage from "../assets/images/onboarding-utilities.jpg";
import AppNav from "../components/AppNav";
import { mdp, t } from "../localization";
import { LayoutContainer } from "../state/withLayout";
import React from "react";
import Button from "react-bootstrap/Button";

export default function Utilities() {
  return (
    <>
      <AppNav />
      <img src={utilitiesImage} className="thin-header-image" alt="Solar Panels" />
      <LayoutContainer top gutters>
        <h2>{t("utilities:page_title")}</h2>
        {mdp("utilities:intro_md")}
        <div className="button-stack">
          <Button variant="outline-primary">{t("common:join_waitlist")}</Button>{" "}
        </div>
      </LayoutContainer>
    </>
  );
}
