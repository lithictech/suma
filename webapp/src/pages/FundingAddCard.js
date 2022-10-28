import api from "../api";
import AddCreditCard from "../components/AddCreditCard";
import GoHome from "../components/GoHome";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import { md, t } from "../localization";
import { extractErrorCode, useError } from "../state/useError";
import { useScreenLoader } from "../state/useScreenLoader";
import { useUser } from "../state/useUser";
import React from "react";

export default function FundingAddCard() {
  const [submitSuccessful, setSubmitSuccessful] = React.useState(false);
  const { user, setUser, handleUpdateCurrentMember } = useUser();
  const screenLoader = useScreenLoader();
  const [error, setError] = useError();

  function handleCardSuccess(stripeToken) {
    screenLoader.turnOn();
    setError("");
    api
      .createCardStripe({ token: stripeToken })
      .tap(handleUpdateCurrentMember)
      .then((r) => {
        setUser({ ...user, usablePaymentInstruments: r.data.allPaymentInstruments });
        setSubmitSuccessful(true);
      })
      .catch((e) => setError(extractErrorCode(e)))
      .finally(screenLoader.turnOff);
  }
  return (
    <>
      {submitSuccessful ? (
        <Success />
      ) : (
        <>
          <LinearBreadcrumbs back />
          <h2 className="page-header">{t("payments:add_card")}</h2>
          <p>{md("payments:payment_intro.privacy_statement_md")}</p>
          <AddCreditCard
            error={error}
            setError={setError}
            onSuccess={handleCardSuccess}
          />
        </>
      )}
    </>
  );
}

function Success() {
  return (
    <>
      <h2>{t("payments:added_card")}</h2>
      {t("payments:added_card_successful")}
      <GoHome />
    </>
  );
}
