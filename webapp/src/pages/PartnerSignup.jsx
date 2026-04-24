import api from "../api.js";
import PageHeading from "../components/PageHeading.jsx";
import PageLoader from "../components/PageLoader.jsx";
import RLink from "../components/RLink.jsx";
import { dt, t } from "../localization/index.jsx";
import useToggle from "../shared/react/useToggle.jsx";
import useErrorToast from "../state/useErrorToast.jsx";
import useUser from "../state/useUser.jsx";
import React from "react";
import Button from "react-bootstrap/Button";
import { Helmet } from "react-helmet-async";
import { useNavigate } from "react-router-dom";

export default function PartnerSignup() {
  const navigate = useNavigate();
  const { user, userUnauthed, userError, userLoading, registrationSession } = useUser();

  if (userLoading) {
    return <PageLoader buffered />;
  }
  if (userError || userUnauthed) {
    // Unauthed users go through the normal signup/in and onboarding flow.
    navigate("/");
    return <PageLoader buffered />;
  }
  if (!user.onboarded) {
    // If the user is not onboarded, they can finish that process
    // with this partner org pre-selected.
    navigate("/onboarding/signup");
    return <PageLoader buffered />;
  }
  if (!registrationSession) {
    // If there is no registration link, let the user know.
    return (
      <>
        <div className="mt-3">{t("onboarding.partner_link_invalid")}</div>
        <div className="button-stack gap-3 mt-4">
          <Button href="/dashboard" variant="primary" as={RLink}>
            {t("common.go_to_dashboard")}
          </Button>
        </div>
      </>
    );
  }
  // Give them the option to join this partner.
  return <JoinPartner />;
}

function JoinPartner() {
  const navigate = useNavigate();
  const loading = useToggle();
  const { showErrorToast } = useErrorToast();
  const { setUser, registrationSession } = useUser();

  const { organizationName, intro } = registrationSession;

  function handleJoin() {
    loading.turnOn();
    api
      .updateMe({})
      .then((r) => {
        setUser(r.data);
        navigate("/dashboard");
      })
      .catch((e) => {
        showErrorToast(e, { extract: true });
        loading.turnOff();
      });
  }
  return (
    <>
      <Helmet>
        <title>Join {organizationName}</title>
      </Helmet>
      <div className="mt-3">{dt(intro)}</div>
      <div className="button-stack gap-3 mt-4">
        <Button variant="primary" onClick={handleJoin}>
          {t("onboarding.partner_accept")}
        </Button>
        <Button href="/dashboard" variant="link" as={RLink}>
          {t("common.go_to_dashboard")}
        </Button>
      </div>
    </>
  );
}
