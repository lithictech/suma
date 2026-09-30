import RLink from "../components/RLink";
import { t } from "../localization";
import useUser from "../state/useUser";
import React from "react";
import Button from "react-bootstrap/Button";

export default function OnboardingFinish() {
  const { user } = useUser();
  return (
    <div className="mt-3">
      <h1 className="visually-hidden">{t("titles.onboarding_finish")}</h1>
      {user.onboarded ? (
        <p>{t("onboarding.finish_onboarded")}</p>
      ) : (
        t("onboarding.finish")
      )}
      <div className="button-stack">
        <Button href="/dashboard" variant="outline-primary" className="mt-3" as={RLink}>
          {t("common.okay_ex")}
        </Button>
      </div>
    </div>
  );
}
