import api from "../api";
import AddCreditCard from "../components/AddCreditCard";
import GoHome from "../components/GoHome";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import RLink from "../components/RLink";
import { md, t } from "../localization";
import { extractErrorCode, useError } from "../state/useError";
import { useScreenLoader } from "../state/useScreenLoader";
import { useUser } from "../state/useUser";
import _ from "lodash";
import React from "react";
import Button from "react-bootstrap/Button";
import { useSearchParams } from "react-router-dom";

export default function FundingAddCard() {
  const [params] = useSearchParams();
  const returnTo = params.get("returnTo");
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
        setSubmitSuccessful({
          instrumentId: r.data.id,
          instrumentType: r.data.paymentMethodType,
        });
      })
      .catch((e) => setError(extractErrorCode(e)))
      .finally(screenLoader.turnOff);
  }
  return (
    <>
      {!_.isEmpty(submitSuccessful) ? (
        <Success {...submitSuccessful} returnTo={returnTo} />
      ) : (
        <>
          <LinearBreadcrumbs back={returnTo || true} />
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

function Success({ instrumentId, instrumentType, returnTo }) {
  return (
    <>
      <h2>{t("payments:added_card")}</h2>
      {t("payments:added_card_successful")}
      {returnTo ? (
        <div className="button-stack mt-4">
          <Button
            href={`${returnTo}?instrumentId=${instrumentId}&instrumentType=${instrumentType}`}
            as={RLink}
            variant="outline-primary"
          >
            {t("forms:continue")}
          </Button>
        </div>
      ) : (
        <GoHome />
      )}
    </>
  );
}
