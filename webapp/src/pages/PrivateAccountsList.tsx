import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import LayoutContainer from "../components/LayoutContainer";
import PageHeading from "../components/PageHeading";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
import { dt, t } from "../localization";
import useAsyncFetch from "../state/useAsyncFetch";
import useMountEffect from "../state/useMountEffect";
import BreadcrumbBack from "../ui/BreadcrumbBack";
import Button from "../ui/Button";
import Card from "../ui/Card";
import CardBody from "../ui/CardBody";
import { Dialog } from "../ui/Dialog";
import DialogHeader from "../ui/DialogHeader";
import Stack from "../ui/Stack";
import ScrollTopOnMount from "../uir/ScrollToTopOnMount";
import isEmpty from "lodash/isEmpty";
import React from "react";

export default function PrivateAccountsList() {
  const {
    state: accounts,
    loading: accountsLoading,
    error: accountsError,
  } = useAsyncFetch<{ items: AnonProxyVendorAccount[] }>(api.getPrivateAccounts, {
    default: { items: [] },
    pickData: true,
  });

  const [modalAccount, setModalAccount] = React.useState<AnonProxyVendorAccount | null>(
    null
  );

  useMountEffect(() => {
    // It's important that we dismiss the modal when the page loses focus.
    // That is an indication usually that the user has opened the vendor's native app
    // from the instructions modal.
    const handleVizChange = () => {
      setModalAccount(null);
    };
    document.addEventListener("visibilitychange", handleVizChange);
    return () => {
      document.removeEventListener("visibilitychange", handleVizChange);
    };
  });

  if (accountsError) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }

  const handleHelp = (o: AnonProxyVendorAccount) => {
    setModalAccount(o);
  };

  return (
    <>
      <LayoutContainer gutters top>
        <BreadcrumbBack back />
        <PageHeading>{t("titles.private_accounts")}</PageHeading>
        <p className="text-secondary">{t("private_accounts.intro")}</p>
      </LayoutContainer>
      <hr className="my-4" />
      <Dialog
        open={!!modalAccount}
        onClose={() => setModalAccount(null)}
        labelledBy="private-account-help-title"
      >
        <DialogHeader id="private-account-help-title">
          {t("private_accounts.help_title", {
            vendorName: modalAccount?.vendorName,
          })}
        </DialogHeader>
        <div className="d-flex justify-content-center align-items-center flex-column m-2">
          <ScrollTopOnMount />
          {dt(modalAccount?.uiStateV1.helpText)}
          <div className="d-flex justify-content-end mt-2">
            <Button variant="outline" onClick={() => setModalAccount(null)}>
              {t("common.close")}
            </Button>
          </div>
        </div>
      </Dialog>
      {accountsLoading ? (
        <PageLoader />
      ) : !isEmpty(accounts.items) ? (
        <LayoutContainer gutters>
          <Stack gap={3}>
            {accounts.items.map((a: AnonProxyVendorAccount) => (
              <Card key={a.id}>
                <CardBody>
                  <PrivateAccount account={a} onHelp={() => handleHelp(a)} />
                </CardBody>
              </Card>
            ))}
          </Stack>
        </LayoutContainer>
      ) : (
        <LayoutContainer>{t("private_accounts.no_private_accounts")}</LayoutContainer>
      )}
    </>
  );
}

function PrivateAccount({
  account,
  onHelp,
}: {
  account: AnonProxyVendorAccount;
  onHelp: () => void;
}) {
  let actionLocKey, ctaVariant, showHelp;
  if (account.uiStateV1.indexCardMode === "link") {
    actionLocKey = "private_accounts.action_link_app";
    ctaVariant = "primary";
    showHelp = false;
  } else if (account.uiStateV1.indexCardMode === "relink") {
    actionLocKey = "private_accounts.action_relink_app";
    ctaVariant = "outline";
    showHelp = true;
  } else {
    actionLocKey = "private_accounts.action_setup_payment";
    ctaVariant = "primary";
    showHelp = false;
  }
  return (
    <Stack direction="vertical" className="align-items-center">
      <SumaImage
        image={account.vendorImage}
        h={80}
        placeholderHeight={80}
        params={{ crop: "none", fmt: "png", flatten: [255, 255, 255] }}
        variant="dark"
        className="mb-4"
        style={{ maxWidth: "100%" }}
      />
      <p>{dt(account.uiStateV1.descriptionText)}</p>
      <Stack direction="horizontal" gap={2}>
        {showHelp && (
          <Button variant="text" className="flex-grow-1" onClick={() => onHelp()}>
            {t("common.help")}
          </Button>
        )}
        <Button
          variant={ctaVariant}
          to={["/private-account/:id", { id: account.id }]}
          className={"flex-grow-1"}
        >
          {t(actionLocKey)}
        </Button>
      </Stack>
    </Stack>
  );
}
