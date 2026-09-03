import { dt, t } from "../localization";
import useMountEffect from "../state/useMountEffect.ts";
import Button, { ButtonVariant } from "../ui/Button.tsx";
import ButtonGroup from "../ui/ButtonGroup.tsx";
import Card from "../ui/Card.tsx";
import CardBody from "../ui/CardBody.tsx";
import { Dialog } from "../ui/Dialog.tsx";
import DialogHeader from "../ui/DialogHeader.tsx";
import Page from "../ui/Page.tsx";
import PageHeader from "../ui/PageHeader.tsx";
import Stack from "../ui/Stack.tsx";
import ScrollTopOnMount from "../uir/ScrollToTopOnMount.ts";
import AsyncContent from "./AsyncContent.tsx";
import SumaImage from "./SumaImage.tsx";
import React from "react";

export interface PrivateAccountsListProps {
  loading?: boolean;
  error?: any;
  accounts: AnonProxyVendorAccount[];
}
export default function PrivateAccountsList({
  loading,
  error,
  accounts,
}: PrivateAccountsListProps) {
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

  const handleHelp = (o: AnonProxyVendorAccount) => {
    setModalAccount(o);
  };

  return (
    <Page appNav>
      <PageHeader title={t("titles.private_accounts")} />

      <p className="text-secondary">{t("private_accounts.intro")}</p>

      <hr className="my-4" />
      <Dialog
        open={!!modalAccount}
        onClose={() => setModalAccount(null)}
        labelledBy="private-account-help"
      >
        <Card>
          <CardBody>
            <DialogHeader id="private-account-help">
              {" "}
              {t("private_accounts.help_title", {
                vendorName: modalAccount?.vendorName,
              })}
            </DialogHeader>
            <div className="d-flex justify-content-center align-items-center flex-column m-2">
              <ScrollTopOnMount />
              {dt(modalAccount?.uiStateV1.helpText || "")}
              <div className="d-flex justify-content-end mt-2">
                <Button variant="outline" onClick={() => setModalAccount(null)}>
                  {t("common.close")}
                </Button>
              </div>
            </div>
          </CardBody>
        </Card>
      </Dialog>
      <AsyncContent loading={loading || false} error={error}>
        {() =>
          accounts.length ? (
            <Stack col gap={3}>
              {accounts.map((a: AnonProxyVendorAccount) => (
                <Card key={a.id}>
                  <CardBody>
                    <PrivateAccount account={a} onHelp={() => handleHelp(a)} />
                  </CardBody>
                </Card>
              ))}
            </Stack>
          ) : (
            t("private_accounts.no_private_accounts")
          )
        }
      </AsyncContent>
    </Page>
  );
}

function PrivateAccount({
  account,
  onHelp,
}: {
  account: AnonProxyVendorAccount;
  onHelp: () => void;
}) {
  let actionLocKey, ctaVariant: ButtonVariant, showHelp: boolean;
  if (account.uiStateV1.indexCardMode === "link") {
    actionLocKey = "private_accounts.action_link_app";
    ctaVariant = "filled";
    showHelp = false;
  } else if (account.uiStateV1.indexCardMode === "relink") {
    actionLocKey = "private_accounts.action_relink_app";
    ctaVariant = "outline";
    showHelp = true;
  } else {
    actionLocKey = "private_accounts.action_setup_payment";
    ctaVariant = "filled";
    showHelp = false;
  }
  return (
    <Stack col center gap={3}>
      <SumaImage
        image={account.vendorImage}
        h={80}
        placeholderHeight={80}
        params={{ crop: "none", fmt: "png", flatten: [255, 255, 255] }}
        style={{ maxWidth: "100%" }}
      />
      <p>{dt(account.uiStateV1.descriptionText)}</p>
      <ButtonGroup row className="w-100">
        {showHelp && (
          <Button variant="text" onClick={onHelp}>
            {t("common.help")}
          </Button>
        )}
        <Button variant={ctaVariant} to={["/private-account/:id", { id: account.id }]}>
          {t(actionLocKey)}
        </Button>
      </ButtonGroup>
    </Stack>
  );
}
