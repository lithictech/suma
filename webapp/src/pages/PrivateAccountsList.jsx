import api from "../api";
import BackBreadcrumb from "../components/BackBreadcrumb.jsx";
import ErrorScreen from "../components/ErrorScreen";
import LayoutContainer from "../components/LayoutContainer";
import PageHeading from "../components/PageHeading.jsx";
import PageLoader from "../components/PageLoader";
import RLink from "../components/RLink.jsx";
import SumaImage from "../components/SumaImage";
import { dt, t } from "../localization";
import ScrollTopOnMount from "../shared/ScrollToTopOnMount";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useMountEffect from "../shared/react/useMountEffect";
import isEmpty from "lodash/isEmpty";
import React from "react";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";
import Modal from "react-bootstrap/Modal";
import Stack from "react-bootstrap/Stack";

export default function PrivateAccountsList() {
  const {
    state: accounts,
    loading: accountsLoading,
    error: accountsError,
  } = useAsyncFetch(api.getPrivateAccounts, {
    default: {},
    pickData: true,
  });

  const [modalAccount, setModalAccount] = React.useState(null);

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

  const handleHelp = (o) => {
    setModalAccount(o);
  };

  return (
    <>
      <LayoutContainer gutters top>
        <BackBreadcrumb back />
        <PageHeading>{t("titles.private_accounts")}</PageHeading>
        <p className="text-secondary">{t("private_accounts.intro")}</p>
      </LayoutContainer>
      <hr className="my-4" />
      <Modal show={!!modalAccount} onHide={() => setModalAccount(null)}>
        <Modal.Header closeButton>
          <Modal.Title>
            {t("private_accounts.help_title", {
              vendorName: modalAccount?.vendorName,
            })}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <div className="d-flex justify-content-center align-items-center flex-column m-2">
            <ScrollTopOnMount />
            {dt(modalAccount?.uiStateV1.helpText)}
            <div className="d-flex justify-content-end mt-2">
              <Button variant="outline-secondary" onClick={() => setModalAccount(null)}>
                {t("common.close")}
              </Button>
            </div>
          </div>
        </Modal.Body>
      </Modal>
      {accountsLoading ? (
        <PageLoader />
      ) : !isEmpty(accounts.items) ? (
        <LayoutContainer gutters>
          <Stack gap={3}>
            {accounts.items.map((a) => (
              <Card key={a.id}>
                <Card.Body>
                  <PrivateAccount account={a} onHelp={() => handleHelp(a)} />
                </Card.Body>
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

/**
 * @param {AnonProxyVendorAccount} account
 * @param onHelp
 */
function PrivateAccount({ account, onHelp }) {
  let actionLocKey, ctaVariant, showHelp;
  if (account.uiStateV1.indexCardMode === "link") {
    actionLocKey = "private_accounts.action_link_app";
    ctaVariant = "primary";
    showHelp = false;
  } else if (account.uiStateV1.indexCardMode === "relink") {
    actionLocKey = "private_accounts.action_relink_app";
    ctaVariant = "outline-primary";
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
      <p>{account.uiStateV1.descriptionText}</p>
      <Stack direction="horizontal" gap={2}>
        {showHelp && (
          <Button variant="link" className="flex-grow-1" onClick={() => onHelp()}>
            {t("common.help")}
          </Button>
        )}
        <Button
          variant={ctaVariant}
          as={RLink}
          to={`/private-account/${account.id}`}
          className={"flex-grow-1"}
        >
          {t(actionLocKey)}
        </Button>
      </Stack>
    </Stack>
  );
}
