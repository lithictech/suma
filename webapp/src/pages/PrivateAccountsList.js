import api from "../api";
import ErrorScreen from "../components/ErrorScreen";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
import SumaMarkdown from "../components/SumaMarkdown";
import { mdp, t } from "../localization";
import ScrollTopOnMount from "../shared/ScrollToTopOnMount";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useToggle from "../shared/react/useToggle";
import { useError } from "../state/useError";
import { useScreenLoader } from "../state/useScreenLoader";
import { LayoutContainer } from "../state/withLayout";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { Stack } from "react-bootstrap";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";
import Modal from "react-bootstrap/Modal";
import Toast from "react-bootstrap/Toast";
import ToastContainer from "react-bootstrap/ToastContainer";

export default function PrivateAccountsList() {
  const {
    state: accounts,
    replaceState: replaceAccounts,
    loading: accountsLoading,
    error: accountsError,
  } = useAsyncFetch(api.getPrivateAccounts, {
    default: {},
    pickData: true,
  });

  const [error, setError] = useError();
  const [viewAccount, setViewAccount] = React.useState(null);

  const screenLoader = useScreenLoader();

  if (error || accountsError) {
    return (
      <LayoutContainer top>
        <ErrorScreen />
      </LayoutContainer>
    );
  }
  if (accountsLoading) {
    return <PageLoader />;
  }
  const handleConfigure = (o) => {
    screenLoader.turnOn();
    api
      .configurePrivateAccount({ id: o.id })
      .then((r) => {
        const { allVendorAccounts, ...rest } = r.data;
        replaceAccounts({ items: allVendorAccounts });
        setViewAccount(rest);
      })
      .catch((e) => setError(e))
      .finally(screenLoader.turnOff);
  };

  const handleHelp = (o) => {
    setViewAccount(o);
  };

  return (
    <>
      <LayoutContainer top>
        <LinearBreadcrumbs back="/dashboard" />
        <h2>{t("mobility:private_accounts_title")}</h2>
        <p className="text-secondary mt-3">{t("mobility:private_accounts_intro")}</p>
      </LayoutContainer>
      <hr />
      <Modal show={!!viewAccount} onHide={() => setViewAccount(null)}>
        <Modal.Header closeButton>
          <Modal.Title>
            {t("mobility:vendor_private_accounts", {
              vendorName: viewAccount?.vendorName,
            })}
          </Modal.Title>
        </Modal.Header>
        <Modal.Body>
          <div className="mt-4 d-flex justify-content-center align-items-center flex-column">
            <ScrollTopOnMount />
            <div className="mt-2 mx-2">
              <SumaMarkdown>{viewAccount?.instructions}</SumaMarkdown>
            </div>
            <div className="d-flex justify-content-end mt-2">
              <Button
                variant="outline-primary"
                className="mt-2"
                onClick={() => setViewAccount(null)}
              >
                {t("common:close")}
              </Button>
            </div>
            {!isEmpty(viewAccount?.recentMessageTextBodies) && (
              <div className="text-muted mt-4">
                <h6>
                  {t("mobility:recent_messages_from_vendor", {
                    vendorName: viewAccount.vendorName,
                  })}
                </h6>
                {viewAccount.recentMessageTextBodies.map((msg, i) => (
                  <p key={`${i}${msg}`} className="small">
                    {msg}
                  </p>
                ))}
              </div>
            )}
          </div>
        </Modal.Body>
      </Modal>
      {!isEmpty(accounts.items) && (
        <LayoutContainer>
          <Stack gap={3}>
            {accounts.items.map((a) => (
              <Card key={a.id} className="px-2 pb-3">
                <Card.Body>
                  <PrivateAccount
                    account={a}
                    onConfigure={() => handleConfigure(a)}
                    onHelp={() => handleHelp(a)}
                  />
                </Card.Body>
              </Card>
            ))}
          </Stack>
        </LayoutContainer>
      )}
      {isEmpty(accounts.items) && (
        <LayoutContainer>{mdp("mobility:no_private_account_vendors")}</LayoutContainer>
      )}
    </>
  );
}

function PrivateAccount({ account, onConfigure, onHelp }) {
  const { address, addressRequired, vendorImage } = account;
  const copyToast = useToggle(false);
  function handleCopyAddress(e) {
    e.preventDefault();
    navigator.clipboard.writeText(address);
    copyToast.turnOn();
  }
  return (
    <Stack direction="vertical" className="align-items-start">
      <SumaImage
        image={vendorImage}
        height={80}
        params={{ crop: "none", fmt: "png", flatten: [255, 255, 255] }}
      />
      {addressRequired ? (
        <Button className="mt-3" onClick={onConfigure}>
          {t("mobility:create_account")}
        </Button>
      ) : (
        <Stack direction="vertical">
          <p className="mt-3 mb-0 text-muted">{t("mobility:username")}</p>
          <p className="lead mb-0">
            {address}
            <Button variant="link" onClick={handleCopyAddress}>
              <i className="bi bi-clipboard2-fill"></i>
            </Button>
          </p>
          <div className="mt-2 d-flex justify-content-around">
            <Button variant="outline-primary" onClick={() => onHelp()}>
              {t("mobility:help")} <i className="ms-2 bi bi-info-circle"></i>
            </Button>
            <Button
              variant="outline-primary"
              className="border-0"
              href={account.appLaunchLink}
            >
              {t("mobility:app")} <i className="ms-2 bi bi-box-arrow-up-right"></i>
            </Button>
          </div>
        </Stack>
      )}
      <ToastContainer className="p-3" position="top-end" style={{ zIndex: 10 }}>
        <Toast
          bg="success"
          onClose={copyToast.turnOff}
          show={copyToast.isOn}
          delay={2000}
          autohide
        >
          <Toast.Body>
            <p className="lead text-light mb-0">{t("mobility:copied_to_clipboard")}</p>
          </Toast.Body>
        </Toast>
      </ToastContainer>
    </Stack>
  );
}
