import { mdp, t } from "../localization";
import { useUser } from "../state/useUser";
import React from "react";
import Button from "react-bootstrap/Button";

export default function OnboardingFinish() {
  const { user } = useUser();
  return (
    <>
      {user.onboarded ? (
        <p>{t("onboarding:finish_onboarded")}</p>
      ) : (
        mdp("onboarding:finish")
      )}
      <div className="button-stack">
        <Button href="/dashboard" variant="outline-primary" className="mt-3">
          {t("common:okay_ex")}
        </Button>
      </div>
    </>
  );
}
