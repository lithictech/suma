import api from "../api";
import loaderRing from "../assets/images/loader-ring.svg";
import Copyable from "../components/Copyable";
import ErrorScreen from "../components/ErrorScreen";
import LinearBreadcrumbs from "../components/LinearBreadcrumbs";
import PageLoader from "../components/PageLoader";
import SumaImage from "../components/SumaImage";
import SumaMarkdown from "../components/SumaMarkdown";
import { mdp, t } from "../localization";
import ScrollTopOnMount from "../shared/ScrollToTopOnMount";
import useAsyncFetch from "../shared/react/useAsyncFetch";
import useMountEffect from "../shared/react/useMountEffect";
import useResettableTimer from "../shared/react/useResettableTimer";
import { useError } from "../state/useError";
import { useScreenLoader } from "../state/useScreenLoader";
import { LayoutContainer } from "../state/withLayout";
import { CanceledError } from "axios";
import isEmpty from "lodash/isEmpty";
import React from "react";
import { Alert, Stack } from "react-bootstrap";
import Button from "react-bootstrap/Button";
import Card from "react-bootstrap/Card";
import Modal from "react-bootstrap/Modal";

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

  React.useEffect(() => {
    if (!accounts?.items) {
      return;
    }
    // Abort any ongoing request when we unmount.
    const controller = new AbortController();
    function pollAndReplace() {
      const reqBody = {
        latestVendorAccountIdsAndAccessCodes: accounts.items.map(
          ({ id, latestAccessCode }) => ({ id, latestAccessCode })
        ),
      };
      return (
        api
          // Poll with a timeout, in case the server stops responding we want to try again.
          .pollForNewAccessCode(reqBody, { timeout: 35000, signal: controller.signal })
          .then((r) => {
            if (r.data.foundChange) {
              replaceAccounts(r.data);
            } else {
              pollAndReplace();
            }
          })
          .catch((r) => {
            // If the request was aborted, don't restart it. Otherwise, do restart it,
            // since it is some unexpected type of error.
            if (r instanceof CanceledError) {
              return;
            }
            pollAndReplace();
          })
      );
    }
    pollAndReplace();
    return () => {
      controller.abort();
    };
  }, [accounts.items, replaceAccounts]);

  useMountEffect(() => {
    // It's important that we dismiss the modal when the page loses focus.
    // That is an indication usually that the user has opened the vendor's native app
    // from the instructions modal.
    const handleVizChange = () => {
      setViewAccount(null);
    };
    document.addEventListener("visibilitychange", handleVizChange);
    return () => {
      document.removeEventListener("visibilitychange", handleVizChange);
    };
  });

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
        <h2>{t("titles:private_accounts")}</h2>
        <p className="text-secondary mt-3">{t("private_accounts:intro")}</p>
      </LayoutContainer>
      <hr />
      <Modal show={!!viewAccount} onHide={() => setViewAccount(null)}>
        <Modal.Header closeButton>
          <Modal.Title>
            {t("private_accounts:vendor_private_accounts", {
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
            <div className="d-flex justify-content-end my-2">
              <Button variant="outline-primary" onClick={() => setViewAccount(null)}>
                {t("common:close")}
              </Button>
            </div>
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
        <LayoutContainer>{mdp("private_accounts:no_private_accounts")}</LayoutContainer>
      )}
    </>
  );
}

function PrivateAccount({ account, onConfigure, onHelp }) {
  const { address, addressRequired, latestAccessCode, vendorImage } = account;

  // Keep the 'loading' box up for 2 minutes
  const [appLaunchTimerActive, triggerAppLaunched] = useResettableTimer({
    storageKey: `anonProxyCodeTimer-${account.id}`,
    interval: 1000 * 60 * 2,
  });

  const handleAppClick = () => {
    triggerAppLaunched(true);
  };

  return (
    <Stack direction="vertical" className="align-items-start">
      <SumaImage
        image={vendorImage}
        height={80}
        params={{ crop: "none", fmt: "png", flatten: [255, 255, 255] }}
      />
      {addressRequired ? (
        <Button className="mt-3" onClick={onConfigure}>
          {t("private_accounts:create_account")}
        </Button>
      ) : (
        <Stack direction="vertical">
          <Alert variant="light" className="bg-white border-0 pb-0">
            <p className="mt-3 mb-0 text-muted">{t("private_accounts:username")}</p>
            <Copyable inline className="lead mb-0" text={address} />
          </Alert>
          <AccessCode
            latestAccessCode={latestAccessCode}
            showPlaceholder={appLaunchTimerActive}
          />
          <div className="mt-3 d-flex justify-content-around">
            <Button variant="outline-primary" onClick={() => onHelp()}>
              {t("common:help")}
            </Button>
            <Button
              variant="outline-primary"
              className="border-0"
              href={account.appLaunchLink}
              onClick={handleAppClick}
            >
              {t("common:app")} <i className="ms-2 bi bi-box-arrow-up-right"></i>
            </Button>
          </div>
        </Stack>
      )}
    </Stack>
  );
}

function AccessCode({ latestAccessCode, showPlaceholder }) {
  if (!latestAccessCode && !showPlaceholder) {
    return null;
  }
  if (latestAccessCode) {
    return (
      <Alert variant="success" className="blinking-alert">
        <p className="mt-1 mb-0 text-muted">{t("private_accounts:access_code")}</p>
        <Copyable inline className="lead mb-0" text={latestAccessCode} />
      </Alert>
    );
  }
  return (
    <Alert variant="info">
      <p className="mt-1 lead mb-0 text-muted">{t("private_accounts:access_code")}</p>
      <p className="lead mb-0">
        {t("private_accounts:loading_code")}
        <img
          src={loaderRing}
          width="80"
          height="80"
          alt={t("private_accounts:loading_code")}
        />
      </p>
    </Alert>
  );
}
