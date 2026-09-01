import api from "../api";
import AddCreditCard from "../components/AddCreditCard";
import config from "../config.ts";
import { t } from "../localization";
import keepDigits from "../modules/keepDigits.ts";
import { PaymentCardParams } from "../modules/payment.ts";
import { untypedRoutePath } from "../routing/RoutePath.ts";
import useNavigate from "../routing/useNavigate.ts";
import useUser from "../state/useUser";
import BreadcrumbBack from "../ui/BreadcrumbBack";
import Page from "../ui/Page.tsx";
import PageHeader from "../ui/PageHeader.tsx";
import React from "react";
import { useSearchParams } from "react-router-dom";

export default function FundingAddCardPage() {
  const [params] = useSearchParams();
  const navigate = useNavigate();
  const returnTo = params.get("returnTo");
  const returnToImmediate = params.get("returnToImmediate");
  const { user, handleUpdateCurrentMember } = useUser();

  const handleSubmit = React.useCallback((v: PaymentCardParams) => {
    const exp = keepDigits(v.expiry);
    const form = new FormData();
    form.set("card[name]", v.name);
    form.set("card[number]", v.number);
    form.set("card[exp_month]", exp[0] + exp[1]);
    form.set("card[exp_year]", exp[2] + exp[3]);
    form.set("card[cvc]", v.cvc);
    const body = new URLSearchParams(
      form as unknown as Record<string, string>
    ).toString();
    return api.axios
      .post("https://api.stripe.com/v1/tokens", body, {
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
          Authorization: `Bearer ${config.stripePublicKey}`,
        },
      })
      .then((r) => {
        const stripeToken = r.data as string;
        return api.createCardStripe({ token: stripeToken });
      });
  }, []);

  return (
    <Page>
      <BreadcrumbBack back={returnTo ? untypedRoutePath(returnTo) : true} />
      <PageHeader title={t("payments.add_card")} />
      <p>{t("payments.payment_intro.privacy_statement")}</p>
      <AddCreditCard
        user={user!}
        navigate={navigate}
        handleUpdateCurrentMember={handleUpdateCurrentMember}
        returnTo={returnTo || undefined}
        returnToImmediate={returnToImmediate || undefined}
        onSubmit={handleSubmit}
      />
    </Page>
  );
}
