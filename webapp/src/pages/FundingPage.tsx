import Funding from "../components/Funding.tsx";
import config from "../config.ts";
import { t } from "../localization";
import useBackendGlobals from "../state/useBackendGlobals.ts";
import useUser from "../state/useUser.ts";
import BreadcrumbBack from "../ui/BreadcrumbBack.tsx";
import Page from "../ui/Page.tsx";
import PageHeader from "../ui/PageHeader.tsx";

export default function FundingPage() {
  const { user, setUser } = useUser();
  const { supportedPaymentMethods } = useBackendGlobals();
  return (
    <Page appNav>
      <BreadcrumbBack back />
      <PageHeader title={t("payments.payment_title")} />
      <Funding
        featureAddFunds={!!config.featureAddFunds}
        user={user!}
        setUser={setUser}
        supportedPaymentMethods={supportedPaymentMethods.items}
      />
    </Page>
  );
}
