import { t } from "../localization";
import useUser from "../state/useUser";
import Button from "../ui/Button";
import React from "react";

export default function OnboardingFinish() {
  const { user } = useUser();
  return (
    <div className="mt-3">
      {user.onboarded ? (
        <p>{t("onboarding.finish_onboarded")}</p>
      ) : (
        t("onboarding.finish")
      )}
      <div className="button-stack">
        <Button href="/dashboard" variant="outline" className="mt-3">
          {t("common.okay_ex")}
        </Button>
      </div>
    </div>
  );
}
