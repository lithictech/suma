import api from "../api";
import AddCreditCard from "../components/AddCreditCard";
import GoHome from "../components/GoHome";
import PageHeading from "../components/PageHeading";
import { t } from "../localization";
import { untypedRoutePath } from "../routing/RoutePath.ts";
import { extractErrorCode, useError } from "../state/useError";
import useScreenLoader from "../state/useScreenLoader";
import useUser from "../state/useUser";
import BreadcrumbBack from "../ui/BreadcrumbBack";
import Button from "../ui/Button";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { useNavigate, useSearchParams } from "react-router-dom";

export default function FundingAddCard() {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const returnTo = params.get("returnTo");
  const returnToImmediate = params.get("returnToImmediate");
  const [submitSuccessful, setSubmitSuccessful] = React.useState<any>(null);
  const { handleUpdateCurrentMember } = useUser();
  const screenLoader = useScreenLoader();
  const [error, setError] = useError();

  const handleCardSuccess = React.useCallback(
    (stripeToken: string) => {
      screenLoader.turnOn();
      setError("");
      api
        .createCardStripe({ token: stripeToken })
        .tap(handleUpdateCurrentMember)
        .then((r: any) => {
          if (returnToImmediate) {
            navigate(
              makeReturnUrl(returnToImmediate, r.data.id, r.data.paymentMethodType)
            );
            return;
          }
          setSubmitSuccessful({
            instrumentId: r.data.id,
            instrumentType: r.data.paymentMethodType,
          });
        })
        .catch((e: any) => setError(extractErrorCode(e)))
        .finally(screenLoader.turnOff);
    },
    [handleUpdateCurrentMember, navigate, returnToImmediate, screenLoader, setError]
  );

  return (
    <>
      {!isEmpty(submitSuccessful) ? (
        <Success {...submitSuccessful} returnTo={returnTo} />
      ) : (
        <>
          <BreadcrumbBack back={returnTo ? untypedRoutePath(returnTo) : true} />
          <PageHeading>{t("payments.add_card")}</PageHeading>
          <p>{t("payments.payment_intro.privacy_statement")}</p>
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

interface SuccessProps {
  instrumentId: number;
  instrumentType: string;
  returnTo: string | null;
}

function Success({ instrumentId, instrumentType, returnTo }: SuccessProps) {
  return (
    <>
      <h2>{t("payments.added_card")}</h2>
      {t("payments.added_card_successful")}
      {returnTo ? (
        <div className="button-stack mt-4">
          <Button
            to={untypedRoutePath(makeReturnUrl(returnTo, instrumentId, instrumentType))}
            variant="outline"
          >
            {t("forms.continue")}
          </Button>
        </div>
      ) : (
        <GoHome />
      )}
    </>
  );
}

function makeReturnUrl(returnTo: string, instrumentId: number, instrumentType: string) {
  return `${returnTo}?instrumentId=${instrumentId}&instrumentType=${instrumentType}`;
}
