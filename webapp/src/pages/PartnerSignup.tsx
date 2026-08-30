import api from "../api";
import TODO from "../components/TODO.tsx";
import { dt, t } from "../localization";
import useNavigate from "../routing/useNavigate";
import { UserContextValue } from "../state/UserProvider";
import useToggle from "../state/useToggle";
import useUser from "../state/useUser";
import Button from "../ui/Button";
import IndeterminateLoader from "../ui/IndeterminateLoader.tsx";
import React from "react";
import { Helmet } from "react-helmet-async";

export default function PartnerSignup() {
  const navigate = useNavigate();
  const userCtx = useUser();

  React.useEffect(() => {
    // Call navigate in a useEffect, or it may be ignored.
    const action = calculateAction(userCtx);
    if (action === UNAUTHED) {
      // Unauthed users go through the normal signup/in and onboarding flow.
      navigate("/");
    } else if (action === NOT_ONBOARDED) {
      navigate("/onboarding");
    }
  }, [navigate, userCtx]);

  const action = calculateAction(userCtx);
  if (action === LOADING) {
    return <IndeterminateLoader />;
  } else if (action === UNAUTHED) {
    return <IndeterminateLoader />;
  } else if (action === NOT_ONBOARDED) {
    // If the user is not onboarded, they can finish that process
    // with this partner org pre-selected.
    return <IndeterminateLoader />;
  } else if (action === INVALID_LINK) {
    // If there is no registration link, let the user know.
    return (
      <>
        <div className="mt-3">{t("onboarding.partner_link_invalid")}</div>
        <div className="button-stack gap-3 mt-4">
          <Button to="/dashboard" variant="primary">
            {t("common.go_to_dashboard")}
          </Button>
        </div>
      </>
    );
  }
  // Give them the option to join this partner.
  return <JoinPartner />;
}

const LOADING = "loading";
const UNAUTHED = "unauthed";
const NOT_ONBOARDED = "not-onboarded";
const INVALID_LINK = "invalid-link";
const JOIN = "join";

/**
 * We need the same logic for the useEffect and render loop, so centralize it.
 */
function calculateAction(userCtx: UserContextValue) {
  const { userLoading, userError, userUnauthed, user, registrationSession } = userCtx;
  if (userLoading) {
    return LOADING;
  }
  if (userError || userUnauthed) {
    return UNAUTHED;
  }
  if (!user!.onboarded) {
    return NOT_ONBOARDED;
  }
  if (!registrationSession) {
    return INVALID_LINK;
  }
  return JOIN;
}

function JoinPartner() {
  const navigate = useNavigate();
  const loading = useToggle();
  // const { showErrorToast } = useErrorToast();
  const { setUser, registrationSession } = useUser();

  const { organizationName, intro } = registrationSession!;

  function handleJoin() {
    loading.turnOn();
    api
      .updateMe({})
      .then((r) => {
        setUser(r.data);
        navigate("/dashboard");
      })
      .catch((e) => {
        // TODO
        // showErrorToast(e, { extract: true });
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
        <Button to="/dashboard" variant="text">
          {t("common.go_to_dashboard")}
        </Button>
        <TODO />
      </div>
    </>
  );
}
