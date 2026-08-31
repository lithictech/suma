import api from "../api";
import AddCreditCard from "../components/AddCreditCard";
import GoHome from "../components/GoHome";
import { t } from "../localization";
import { AppError, extractAppErrorAny } from "../modules/feedback.ts";
import { untypedRoutePath } from "../routing/RoutePath.ts";
import useScreenLoader from "../state/useScreenLoader";
import useUser from "../state/useUser";
import BreadcrumbBack from "../ui/BreadcrumbBack";
import Button from "../ui/Button";
import PageHeader from "../ui/PageHeader.tsx";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { useNavigate, useSearchParams } from "react-router-dom";

export default function FundingAddCardPage() {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const returnTo = params.get("returnTo");
  const returnToImmediate = params.get("returnToImmediate");
  const [submitSuccessful, setSubmitSuccessful] = React.useState<any>(null);
  const { handleUpdateCurrentMember } = useUser();
  const screenLoader = useScreenLoader();
  const [error, setError] = React.useState<AppError | null>();

  const handleCardSuccess = React.useCallback(
    (stripeToken: string) => {
      screenLoader.turnOn();
      setError(null);
      api
        .createCardStripe({ token: stripeToken })
        .tap(handleUpdateCurrentMember)
        .then((r) => {
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
        .catch((e) => setError(extractAppErrorAny(e)))
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
          <PageHeader title={t("payments.add_card")} />
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
