import api from "../api";
import AddCreditCard from "../components/AddCreditCard";
import GoHome from "../components/GoHome";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import { md, t } from "../localization";
import useToggle from "../shared/react/useToggle";
import { extractErrorCode, useError } from "../state/useError";
import { useScreenLoader } from "../state/useScreenLoader";
import { useUser } from "../state/useUser";
import React from "react";
import { useNavigate, useSearchParams } from "react-router-dom";

export default function FundingAddCard() {
  const [params] = useSearchParams();
  const returnTo = params.get("returnTo");
  const navigate = useNavigate();
  const submitSuccessful = useToggle(false);
  const { handleUpdateCurrentMember } = useUser();
  const screenLoader = useScreenLoader();
  const [error, setError] = useError();

  const handleCardSuccess = React.useCallback(
    (stripeToken) => {
      screenLoader.turnOn();
      setError("");
      api
        .createCardStripe({ token: stripeToken })
        .tap(handleUpdateCurrentMember)
        .then((r) => {
          if (returnTo) {
            const checkoutURL = `${returnTo}?instrumentId=${r.data.id}&instrumentType=${r.data.paymentMethodType}`;
            navigate(checkoutURL);
          }
          submitSuccessful.turnOn();
        })
        .catch((e) => setError(extractErrorCode(e)))
        .finally(screenLoader.turnOff);
    },
    [
      handleUpdateCurrentMember,
      screenLoader,
      setError,
      returnTo,
      navigate,
      submitSuccessful,
    ]
  );

  if (submitSuccessful.isOn) {
    return (
      <>
        <h2>{t("payments:added_card")}</h2>
        {t("payments:added_card_successful")}
        <GoHome />
      </>
    );
  }

  return (
    <>
      <LinearBreadcrumbs back={returnTo || true} />
      <h2 className="page-header">{t("payments:add_card")}</h2>
      <p>{md("payments:payment_intro.privacy_statement")}</p>
      <AddCreditCard error={error} setError={setError} onSuccess={handleCardSuccess} />
    </>
  );
}
