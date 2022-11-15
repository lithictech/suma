import { mdp, t } from "../localization";
import React from "react";
import Button from "react-bootstrap/Button";

export default function OnboardingFinish() {
  return (
    <>
      {mdp("onboarding:finish_md")}
      <div className="button-stack">
        <Button href="/dashboard" variant="outline-primary" className="mt-3">
          {t("common:okay_ex")}
        </Button>
      </div>
    </>
  );
}
